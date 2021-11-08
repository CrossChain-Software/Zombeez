# -*- coding: utf-8 -*-

import requests as r
import requests
from pathlib import Path


def generate_metadata(id, accessory, background, body, clothes, eyes, head, mouth):
    metadata = {}
    metadata["name"] = f'ZOMBEEZ {id}'
    metadata["description"] = 'ZOMBEEZ'
    metadata["image"] = ''
    metadata["attributes"] = [{
                                "trait_type": "Background", 
                                "value": background.title()
                              },
                              {
                                "trait_type": "Accessory", 
                                "value": accessory.title()
                              },
                              {
                                "trait_type": "Body", 
                                "value": body.title()
                              },
                              {
                                "trait_type": "Clothes", 
                                "value": clothes.title()
                              },
                              {
                                "trait_type": "Eyes", 
                                "value": eyes.title()
                              },
                              {
                                "trait_type": "Head", 
                                "value": head.title()
                              },
                              {
                                "trait_type": "Mouth", 
                                "value": mouth.title()
                              }
                             ]
    return metadata


def upload_to_ipfs(filepath, name):
    with Path(filepath).open("rb") as fp:
    	image_binary = fp.read()
    	ipfs_url = "http://localhost:5001"
    	response = requests.post(ipfs_url + "/api/v0/add", files={"file": image_binary})
    	ipfs_hash = response.json()['Hash']
    	uri_for_opensea = "https://ipfs.io/ipfs/{}".format(ipfs_hash)
    	response = requests.post(f"{ipfs_url}/api/v0/pin/remote/add?arg={ipfs_hash}&name={name}&service=Pinata")
    	return uri_for_opensea