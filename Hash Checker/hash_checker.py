#!/usr/bin/python
#
# gethash function taken from:
# https://github.com/munki/munki
#
# This script will check hashes and update them in the bootstrap file required to run
# InstallApplications.py
#
# both the script and the bootstrap.json files should be in the same folder for the
# script to work
#
# writting by Hani Alshikh

import urllib
import hashlib
import json
import os

def gethash(filename):
    hash_function = hashlib.sha256()
    if not os.path.isfile(filename):
        return 'NOT A FILE'

    fileref = open(filename, 'rb')
    while 1:
        chunk = fileref.read(2**16)
        if not chunk:
            break
        hash_function.update(chunk)
    fileref.close()
    return hash_function.hexdigest()


def download(url, item_path):
    urllib.urlretrieve(url, item_path)
    return item_path



def main():

    # Variables
    jsonpath = str(os.path.dirname(os.path.realpath(__file__))) + "/bootstrap.json"
    item_tmp_path = "/var/tmp/item"
    
    # Load up the bootstrap file to grab all the items.
    with open(jsonpath) as json_file:
        json_data = json.load(json_file)

    # read the stages
    for stage in json_data:
        # read the items inside the stages 
        for item in json_data[stage]:
            # download every item and genrate his hash
            hash_new = gethash(download(item['url'], item_tmp_path))
            # check if the hashes matches and correct them if not
            if not item['hash'] == hash_new:
                print("processing %s \n Old Hash: %s \n New Hash: %s" % (item['name'], item['hash'], hash_new))
                item['hash'] = hash_new
            else:
                print("nothing to do for " + str(item['name']))

    # write the new changes
    with open(jsonpath, "w") as json_file:
        json.dump(json_data, json_file, indent=2, sort_keys=True)
    # cleaning 
    os.remove(item_tmp_path)

if __name__ == '__main__':
    main()