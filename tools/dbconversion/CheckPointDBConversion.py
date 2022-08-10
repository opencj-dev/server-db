import pymysql.cursors
import math
import sys

# If set to False, it's CoD4. Otherwise CoD2.
for_cod2 = False


connection = pymysql.connect(host='opencj.org', port=3306, user='openCJ', password='opencjpassword',
                             database='openCJ_cod2' if for_cod2 else 'openCJ_cod4',
                             cursorclass=pymysql.cursors.DictCursor, autocommit=True)


def main():
    """
    Convert JH checkpoints table into OpenCJ checkpoints table
    """
    with connection:
        with connection.cursor() as cursor:
            # Select the map names and map ids from the original table
            sql1 = "SELECT mapName,mapId FROM original_mapids"
            cursor.execute(sql1)
            result = cursor.fetchall()
            #print('All fetched mapName,mapIds: <{}>'.format(result))

            # Loop through each dict in the result (each dict has a mapName and mapId)
            for d1 in result:
                mapname, mapid = d1.values()

                # Select all checkpoint info from original table
                sql2 = "SELECT a.cp_id,a.coordinate_x,a.coordinate_y,a.coordinate_z,a.coordinate_x2,a.coordinate_y2,a.coordinate_z2,a.radius,a.ender,group_concat(b.child_cp_id),type FROM original_checkpoints AS a LEFT JOIN original_checkpoint_connections AS b ON a.cp_id=b.cp_id WHERE a.mapid=" + str(mapid) + " AND (a.isend=0 OR a.isend=1) GROUP BY a.cp_id"
                cursor.execute(sql2)
                cpinfo = cursor.fetchall()
                print('Received from SELECT: {}'.format(cpinfo))

                print('Using mapname={},mapid={} for sql3'.format(mapname, mapid))
                sql3 = "INSERT INTO mapids (mapname) VALUES ('" + mapname + "')"
                print('Executing query: {}'.format(sql3))
                cursor.execute(sql3)
                sql4 = "SELECT mapID,mapname FROM mapids WHERE mapname='" + mapname + "'"
                cursor.execute(sql4)
                result = cursor.fetchone()
                print('Received new mapID,mapname from sql4: {}, {}'.format(result['mapID'], result['mapname']))

                # Loop through the fields in the checkpoint info
                old_new_cp_mapping = {}
                for d2 in cpinfo:
                    cp_id, x1, y1, z1, x2, y2, z2, radius, ender, linked_cp_ids, type_v = d2.values()
                    cp_id = str(cp_id)
                    #if x2, y2, z2 exist then insert (x+x2)/2, y, z etc and set radius |p1-p2| / (2 * sqrt(2))
                    if x2 is not None and y2 is not None and z2 is not None:
                        x = str(int((x1 + x2) / 2))
                        y = str(int((y1 + y2) / 2))
                        z = str(int((z1 + z1) / 2))
                        radius = str(int(math.sqrt(((x2 - x1) * (x2 - x1)) + ((y2 - y1) * (y2 - y1)) + ((z2 - z1) * (z2 - z1))) / (2 * math.sqrt(2))))
                    else:
                        x, y, z = str(x1), str(y1), str(z1)
                        radius = str(radius) if radius is not None else "NULL"

                    if type_v is not None and 'onground' in type_v.lower():
                        on_ground = '1'
                    else:
                        on_ground = '0'

                    # We're about to insert a checkpoint, so we want to do a clean
                    sql5 = "SELECT last_insert_id(NULL)"
                    cursor.execute(sql5)

                    # Insert the (converted) values into new table
                    if ender is not None:
                        ender = ender.replace("'", "\\'")
                        ender = ("'" + ender + "'")
                    else:
                        ender = "NULL"

                    sql6 = "INSERT INTO checkpoints (x,y,z,radius,onGround,mapID,ender) VALUES ({},{},{},{},{},{},{})".format(x, y, z, radius, on_ground, result['mapID'], ender)
                    cursor.execute(sql6)

                    sql7 = "SELECT last_insert_id() AS new_cp_id"
                    cursor.execute(sql7)
                    result_sql7 = cursor.fetchone()
                    new_cp_id = result_sql7['new_cp_id']
                    print('Got new_cp_id={}', new_cp_id)

                    # Remember newly created auto-generated id linked to old checkpoint id
                    old_new_cp_mapping[cp_id] = (new_cp_id, linked_cp_ids)

                # We're done going through all checkpoint info
                for new_cp_id, linked_cp_ids in old_new_cp_mapping.values():
                    print('new_cp_id={}, linked_cp_ids={})'.format(new_cp_id, linked_cp_ids))
                    if linked_cp_ids is not None:
                        try:
                            linked_id_list = linked_cp_ids.split(',')
                        except Exception:
                            linked_id_list = [linked_cp_ids]

                        print('linked_id_list={}'.format(linked_id_list))

                        for linked_id in linked_id_list:
                            try:
                                child_new_cp_id, _ = old_new_cp_mapping[linked_id]
                                sql8 = "INSERT INTO checkpointConnections(cpID,childcpID) VALUES ({},{})".format(new_cp_id, child_new_cp_id)
                                cursor.execute(sql8)
                            except Exception:
                                print('Huh, child ID does not exist?!')
                                sys.exit(1)


if __name__ == '__main__':
    main()
