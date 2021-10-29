from PIL import Image
import random
import os
import json
import asset_chance
import asset_mapping

# Order of operations (he means this backwards...)
# Accessory 
# Head
# Clothes
# Eyes
# Mouth
# Body
# BG

def select_asset(asset_list: list, weights: list) -> str:
    return random.choices(asset_list, weights)


ASSET_DIR = '/zombeez_assets/'


for x in range(0, 8327):
    print(x)
    # This should prob be a function... oh well
    bg_choice = select_asset(list(asset_chance.background.keys()), list(asset_chance.background.values()))[0]
    bg_png = Image.open(f'{os.getcwd()}/{asset_mapping.background[bg_choice]}')
    body_choice = select_asset(list(asset_chance.body.keys()), list(asset_chance.body.values()))[0]
    body_png = Image.open(f'{os.getcwd()}/{asset_mapping.body[body_choice]}')
    mouth_choice = select_asset(list(asset_chance.mouth.keys()), list(asset_chance.mouth.values()))[0]
    mouth_png = Image.open(f'{os.getcwd()}/{asset_mapping.mouth[mouth_choice]}')
    eyes_choice = select_asset(list(asset_chance.eyes.keys()), list(asset_chance.eyes.values()))[0]
    eyes_png = Image.open(f'{os.getcwd()}/{asset_mapping.eyes[eyes_choice]}')
    clothes_choice = select_asset(list(asset_chance.clothes.keys()), list(asset_chance.clothes.values()))[0]
    clothes_png = Image.open(f'{os.getcwd()}/{asset_mapping.clothes[clothes_choice]}')
    head_choice = select_asset(list(asset_chance.head.keys()), list(asset_chance.head.values()))[0]
    head_png = Image.open(f'{os.getcwd()}/{asset_mapping.head[head_choice]}')
    accesory_choice = select_asset(list(asset_chance.accessory.keys()), list(asset_chance.accessory.values()))[0]

    bg_png.paste(body_png, (0,0), body_png)
    bg_png.paste(mouth_png, (0,0), mouth_png)
    bg_png.paste(eyes_png, (0,0), eyes_png)
    bg_png.paste(clothes_png, (0,0), clothes_png)
    bg_png.paste(head_png, (0,0), head_png)
    if accesory_choice != 'NONE':
        assesory_png = Image.open(f'{os.getcwd()}/{asset_mapping.accessory[accesory_choice]}')
        bg_png.paste(assesory_png, (0,0), assesory_png)
    resized_img = bg_png.resize((600, 600), resample=Image.NEAREST)
    resized_img.save(f'images/{x}.png', 'PNG')
    # Upload image to ipfs
    # Save json with ipfs hash (no need to upload individually, we will do as a directory!)