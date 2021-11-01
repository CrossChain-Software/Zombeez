from PIL import Image
import random
import os
import json
import asset_chance
import asset_mapping
import ipfs

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

for x in range(1, 8327):
    print(x)
    # This should prob be a function... oh well
    bg_choice = select_asset(list(asset_chance.background.keys()), list(asset_chance.background.values()))[0]
    bg_png = Image.open(f'{os.getcwd()}/{asset_mapping.background[bg_choice]}')
    body_choice = select_asset(list(asset_chance.body.keys()), list(asset_chance.body.values()))[0]
    body_png = Image.open(f'{os.getcwd()}/{asset_mapping.body[body_choice]}')
    mouth_choice = select_asset(list(asset_chance.mouth.keys()), list(asset_chance.mouth.values()))[0]
    eyes_choice = select_asset(list(asset_chance.eyes.keys()), list(asset_chance.eyes.values()))[0]
    clothes_choice = select_asset(list(asset_chance.clothes.keys()), list(asset_chance.clothes.values()))[0]
    head_choice = select_asset(list(asset_chance.head.keys()), list(asset_chance.head.values()))[0]
    accessory_choice = select_asset(list(asset_chance.accessory.keys()), list(asset_chance.accessory.values()))[0]
    
    print(mouth_choice, eyes_choice, clothes_choice, head_choice, accessory_choice)
    
    bg_png.paste(body_png, (0,0), body_png)
    if mouth_choice != 'NONE':
        mouth_png = Image.open(f'{os.getcwd()}/{asset_mapping.mouth[mouth_choice]}')
        bg_png.paste(mouth_png, (0,0), mouth_png)
    if eyes_choice != 'NONE':
        eyes_png = Image.open(f'{os.getcwd()}/{asset_mapping.eyes[eyes_choice]}')
        bg_png.paste(eyes_png, (0,0), eyes_png)
    if clothes_choice != 'NONE':
        clothes_png = Image.open(f'{os.getcwd()}/{asset_mapping.clothes[clothes_choice]}')
        bg_png.paste(clothes_png, (0,0), clothes_png)
    if head_choice != 'NONE':
        head_png = Image.open(f'{os.getcwd()}/{asset_mapping.head[head_choice]}')
        bg_png.paste(head_png, (0,0), head_png)
    if accessory_choice != 'NONE':
        assessory_png = Image.open(f'{os.getcwd()}/{asset_mapping.accessory[accessory_choice]}')
        bg_png.paste(assessory_png, (0,0), assessory_png)
    resized_img = bg_png.resize((600, 600), resample=Image.NEAREST)
    resized_img.save(f'images/{x}.png', 'PNG')
    img_url = ipfs.upload_to_ipfs(f'images/{x}.png')
    metadata = ipfs.generate_metadata(id, accessory_choice, bg_choice, body_choice, clothes_choice, 
                                      eyes_choice, head_choice, mouth_choice)
    metadata["image"] = img_url
    print(img_url)
    with open(f'jsons/{x}'.json, 'w') as w:
        json.dump(metadata, w)