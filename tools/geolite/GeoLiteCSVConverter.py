import os
import sys
import logging
import socket
import struct
import re
from unidecode import unidecode


_GEOLITE_COUNTRY_BLOCKS_IPV4_FILE_NAME = 'GeoLite2-Country-Blocks-IPv4.csv'
_GEOLITE_COUNTRY_LOC_ENGLISH_FILE_NAME = 'GeoLite2-Country-Locations-en.csv'
_OUTPUT_FILE_IP_CSV_FILE_NAME = 'opencj_ip_country_map.csv'
_OUTPUT_FILE_CONT_CSV_FILE_NAME = 'opencj_country_continent_map.csv'

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# To store an IP with a matching geoID
_IP_GEOID_MAP = {}

# To store a geo id with a country iso code
_GEOID_COUNTRY_ISO_MAP = {}

# Merged ip <-> country iso code dict
_IP_COUNTRY_ISO_MAP = {}


def parse_country_blocks(cb_file):
    """
    Parse a GeoLite2 Country Blocks IPv4 file and store results in internal dict
    :param cb_file: CSV file to parse
    """
    # Found both files at this point
    with open(cb_file, "r") as cb_f:
        lines = cb_f.readlines()
        # CSV format of this file is as follows at the time of writing the script:
        #   [0] = network
        #   [1] = geoname_id
        #   [2] = registered_country_geoname_id
        #   [3] = represented_country_geoname_id
        #   [4] = is_anonymous_proxy
        #   [5] = is_satellite_provider
        for line in lines:
            try:
                network, geoname_id, _, _, _, _ = line.split(',')
            except ValueError:
                logger.warning('Skipping line as format is unexpected:' + os.linesep + '"%s"', line)
                continue

            # Let's see if we can properly parse a start IP from this
            try:
                ip = network.split('/')[0]  # Get rid of subnet mask part
            except ValueError:
                ip = network  # Then let's presume it's just an IP without subnet mask part

            # Make sure this is a valid IPv4 address, otherwise we skip the row
            try:
                socket.inet_aton(ip)
            except socket.error:
                # Silently skip first line as it's probably column names
                if line != lines[0]:
                    logger.warning('Skipping line as network does not contain a valid IP: "%s"', ip)
                continue

            # We have a valid IP, store this entry in the dict
            _IP_GEOID_MAP[ip] = geoname_id


def parse_country_locations(cl_file):
    """
    Parse a GeoLite2 Country Locations file and store results in internal dict
    :param cl_file: CSV file to parse
    """
    with open(cl_file, "r", encoding='utf-8') as cl_f:
        lines = cl_f.readlines()
        # CSV format of this file is as follows at the time of writing the script:
        #   [0] = geoname_id
        #   [1] = locale_code
        #   [2] = continent_code
        #   [3] = continent_name
        #   [4] = country_iso_code
        #   [5] = country_name (can contain commas...)
        #   [6] = is_in_european_union
        # However because country_name can contain commas, we use a safer regex instead of split by comma
        for line in lines:
            is_line_invalid = True  # Pessimism
            try:
                # First try to find any illegal match so we skip the line as invalid
                illegal_line_pattern = "^.*,,.*$" # Anything where any data is missing results in duplicate commas
                illegal_matches = re.search(illegal_line_pattern, line)
                if illegal_matches is None:
                    # Example:
                    # 7626844,en,NA,"North America",BQ,"Bonaire, Sint Eustatius, and Saba",0
                    pattern = r'^(\d+),([a-zA-Z]+),([a-zA-Z]+),"*?([^"]+)"*?,([a-zA-Z]{2}),"*?([^"]+)"*?,(\d)$'
                    matches = re.search(pattern, line)
                    if matches is not None:
                        groups = matches.groups()
                        nr_groups = len(groups)
                        logger.debug('Found %d groups', nr_groups)

                        if nr_groups == 7: # 0 through 6, see description before the for loop
                            geoname_id, _, continent_code, _, country_iso_code, country_name, _ = groups
                            is_line_invalid = False
            except ValueError:
                pass  # Invalid

            # Log any invalid lines and skip to the next line
            if is_line_invalid:
                logger.warning('Skipping line as it is invalid:' + os.linesep + '%s', line)
                continue

            # We have a geoname ID and a country iso code, store this entry in the dict
            # Country name could contain special characters, let's normalize those first
            _GEOID_COUNTRY_ISO_MAP[geoname_id] = (country_iso_code, unidecode(country_name), continent_code)


def merge_and_write_ip_country_csv(o_file):
    """
    Merge the internal dictionaries so that we can map a start IP to a country iso code.
    Afterwards, write the merged dict to the specified output file
    :param o_file: The name of the output CSV file to write to (gets overwritten)
    """
    # This can be made more efficient, but I'm not sure if the order in both CSV's will always be the same.
    # Better safe than sorry, iterate through both
    logger.info('Merging dictionaries..')
    if len(_IP_GEOID_MAP) > 0:
        for ip, geo_id_a in _IP_GEOID_MAP.items():
            for geo_id_b, tup in _GEOID_COUNTRY_ISO_MAP.items():
                country_iso_code, _, _ = tup
                if geo_id_a == geo_id_b:
                    logger.debug('Matched IP "%s" with country iso code "%s"', ip, country_iso_code)
                    _IP_COUNTRY_ISO_MAP[ip] = country_iso_code

        # Convert IP from string to uint32 and write results to output file
        logger.info('Converting IPs and writing to output file..')
        if len(_IP_COUNTRY_ISO_MAP) > 0:
            # If we have something, write everything we have to the output file
            with open(o_file, "w") as o_f:
                is_first_entry = True
                for ip_str, country_iso_code in _IP_COUNTRY_ISO_MAP.items():
                    ip = struct.unpack('!I', socket.inet_aton(ip_str))[0]
                    logger.debug('Writing "%s,%s"', ip, country_iso_code)
                    o_f.write(('' if is_first_entry else '\n') + str(ip) + ',' + country_iso_code)  # Do not use os.linesep
                    is_first_entry = False
        else:
            logger.error('_IP_COUNTRY_ISO_MAP{ is empty.. nothing to do')
            sys.exit(1)
    else:
        logger.warning('_IP_GEOID_MAP is empty.. nothing to do')
        sys.exit(1)


def convert_and_write_country_csv(o_file):
    """
    Write the required information for country<->continent mapping to a CSV
    :param o_file: The name of the output CSV
    """
    if len(_GEOID_COUNTRY_ISO_MAP) > 0:
        with open(o_file, "w") as o_f:
            is_first_entry = True
            for _, tup in _GEOID_COUNTRY_ISO_MAP.items():
                country_iso_code, country_name, continent_code = tup
                country_name = '"' + str(country_name) + '"'
                o_f.write(('' if is_first_entry else '\n') + str(country_iso_code) +
                          ',' + country_name + ',' + str(continent_code))
                is_first_entry = False
    else:
        logger.error('_GEOID_COUNTRY_ISO_MAP is empty.. nothing to do')
        sys.exit(1)


def main():
    """
    Merge GeoLite2 Country Blocks and Country Location into an OpenCJ compatible CSV file (uint32_t IP, char[2] country)
    """
    # First make a list of all CSV files in current directory
    csv_files = [f for f in os.listdir('.') if os.path.isfile(f) and f.endswith(".csv")]

    # For now we specifically look at a specific name, if the name changes it might mean the format changed
    cb_files = [f for f in csv_files if f == _GEOLITE_COUNTRY_BLOCKS_IPV4_FILE_NAME]  # GeoLite Country Blocks file
    cl_files = [f for f in csv_files if f == _GEOLITE_COUNTRY_LOC_ENGLISH_FILE_NAME]  # GeoLite Country Location file

    if cb_files is None or len(cb_files) == 0:
        logger.error('Could not find file: "%s"', _GEOLITE_COUNTRY_BLOCKS_IPV4_FILE_NAME)
        sys.exit(1)
    if cl_files is None or len(cl_files) == 0:
        logger.error('Could not find file: "%s"', _GEOLITE_COUNTRY_LOC_ENGLISH_FILE_NAME)
        sys.exit(1)

    # There can never be two files with exactly the same name, so we can safely convert list to string from index 0
    cb_filename = cb_files[0]
    cl_filename = cl_files[0]

    # The following functions will cause the script to exit if something goes wrong

    # Parse country blocks (IP <-> geoname_id)
    logger.info('Parsing IPv4 Country Blocks..')
    parse_country_blocks(cb_filename)

    # Parse country locations (geoname_id <-> country_iso_code)
    logger.info('Parsing Country Locations..')
    parse_country_locations(cl_filename)

    # Great, now we filled our internal dictionaries and can merge the dicts and create the output file
    logger.info('Merging Country Blocks and Locations and writing results to output CSV: %s',
                _OUTPUT_FILE_IP_CSV_FILE_NAME)
    merge_and_write_ip_country_csv(_OUTPUT_FILE_IP_CSV_FILE_NAME)

    # Write the other CSV, which maps the country_iso_code, country_name, continent_code
    logger.info('Creating Country<->Continent CSV: %s', _OUTPUT_FILE_CONT_CSV_FILE_NAME)
    convert_and_write_country_csv(_OUTPUT_FILE_CONT_CSV_FILE_NAME)

    logger.info('All done!')


if __name__ == "__main__":
    main()
