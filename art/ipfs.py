# -*- coding: utf-8 -*-

import requests as r
import requests
from pathlib import Path


def generate_metadata(id, accessory, background, body, clothes, eyes, head, mouth):
    metadata = {}
    metadata["name"] = f'ZOMBEEZ {id}'
    metadata["description"] = 'Eurphoric generative art made with AI'
    metadata["image"] = ''
    metadata["attributes"] = {"Background": background.title(),
                              "Accessory": accessory.title(),
                              "Body": body.title(),
                              "Clothes": clothes.title(),
                              "Eyes": eyes.title(),
                              "Head": head.title(),
                              "Mouth": mouth.title()
                             }
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