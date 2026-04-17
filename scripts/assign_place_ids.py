import json
import random
import string

CHARS = string.digits + string.ascii_letters  # 0–9 A–Z a–z (base62, 62 chars)
ID_LEN = 8


def assign_ids():
    path = 'thirstyinrome/Places.json'
    with open(path, encoding='utf-8') as f:
        places = json.load(f)

    seen = set()
    updated = []
    for place in places:
        while True:
            new_id = ''.join(random.choices(CHARS, k=ID_LEN))
            if new_id not in seen:
                seen.add(new_id)
                break
        updated.append({'id': new_id, **place})

    with open(path, 'w', encoding='utf-8') as f:
        json.dump(updated, f, indent=2, ensure_ascii=False)
        f.write('\n')

    print(f'Assigned stable IDs to {len(updated)} places.')


if __name__ == '__main__':
    assign_ids()
