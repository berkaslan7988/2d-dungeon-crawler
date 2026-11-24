"""Writes i18n/strings.csv (keys, en, tr), which Godot imports as two
translations. Edit the tables here, then run:  python tools/i18n_build.py

Item and boon names are only given in English: in Turkish the game falls
back to the names in the .tres files, which are Turkish.
"""
import csv
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "i18n" / "strings.csv"

UI = {
    "GAME_TITLE": ("Sunless Crown", "Güneşsiz Taç"),
    "TITLE_TAGLINE": ("Nine floors · Three Wardens · One ember", "Dokuz kat · Üç Muhafız · Tek bir köz"),
    "TITLE_DESCEND": ("Descend", "Başla"),
    "TITLE_ALTAR": ("Altar of Souls", "Ruhlar Sunağı"),
    "TITLE_SETTINGS": ("Settings", "Ayarlar"),
    "TITLE_QUIT": ("Quit", "Çık"),
    "TITLE_HINT": ("W S CHOOSE · ENTER CONFIRM", "W S SEÇ · ENTER ONAYLA"),
    "TITLE_BEST_FLOOR": ("BEST FLOOR", "EN DERİN KAT"),
    "COMMON_SOULS": ("SOULS", "RUH"),
    "COMMON_SOULS_SHORT": ("souls", "ruh"),
    "COMMON_BACK": ("Back", "Geri"),
    "COMMON_CONTINUE": ("CONTINUE", "DEVAM"),
    "COMMON_ON": ("On", "Açık"),
    "COMMON_OFF": ("Off", "Kapalı"),
    "SETTINGS_TITLE": ("Settings", "Ayarlar"),
    "SETTINGS_LANGUAGE": ("Language", "Dil"),
    "SETTINGS_MASTER": ("Volume", "Ses"),
    "SETTINGS_MUSIC": ("Music", "Müzik"),
    "SETTINGS_SFX": ("Effects", "Efektler"),
    "SETTINGS_FULLSCREEN": ("Fullscreen", "Tam ekran"),
    "SETTINGS_SHAKE": ("Screen shake", "Ekran sarsıntısı"),
    "ALTAR_TITLE": ("Altar of Souls", "Ruhlar Sunağı"),
    "ALTAR_SUBTITLE": ("Offer souls for boons that stay with you every run.",
                       "Ruh sun, her koşuda seninle kalacak lütuflar al."),
    "ALTAR_OWNED": ("Owned", "Alındı"),
    "BOON_LEVEL": ("Level %d", "Seviye %d"),
    "BOON_CHOOSE": ("Choose a boon", "Bir lütuf seç"),
    "BOON_HINT": ("1 · 2 · 3 OR CLICK · THE DARK WAITS UNTIL YOU CHOOSE",
                  "1 · 2 · 3 YA DA TIKLA · SEÇENE DEK KARANLIK BEKLER"),
    "CHEST_TITLE": ("Treasure chest", "Hazine sandığı"),
    "CHEST_TAKE": ("Take all (E)", "Hepsini al (E)"),
    "CHEST_EMPTY": ("The chest was empty…", "Sandık boştu…"),
    "CHEST_BOON": ("Boon", "Lütuf"),
    "END_DEATH": ("The ember goes out", "Köz söndü"),
    "END_DEATH_SUB": ("Your souls return to the altar.", "Ruhların sunağa döner."),
    "END_VICTORY": ("The curse is broken", "Lanet kırıldı"),
    "END_VICTORY_SUB": ("The sun rises over Aethelgard again.", "Aethelgard'da güneş yeniden doğuyor."),
    "END_FLOOR": ("FLOOR REACHED", "ULAŞILAN KAT"),
    "END_SLAIN": ("SLAIN", "ÖLDÜRÜLEN"),
    "END_LEVEL": ("LEVEL", "SEVİYE"),
    "END_TIME": ("TIME", "SÜRE"),
    "END_SOULS": ("SOULS EARNED", "KAZANILAN RUH"),
    "END_RETRY": ("Descend again", "Yeniden başla"),
    "END_MENU": ("Title screen", "Ana menü"),
    "HUD_FLOOR": ("FLOOR", "KAT"),
    "HUD_DASH": ("DASH", "ATIL"),
    "HUD_DMG": ("DMG", "HSR"),
    "HUD_LV": ("LV", "SV"),
    "HUD_UNARMED": ("Unarmed", "Silahsız"),
    "PAUSE_TITLE": ("Paused", "Duraklatıldı"),
    "PAUSE_RESUME": ("Resume", "Devam et"),
    "PAUSE_MAIN_MENU": ("Title screen", "Ana menü"),
    "PAUSE_CONFIRM": ("Return to the title screen? This run will be lost.",
                      "Ana menüye dönülsün mü? Bu koşu kaybolacak."),
    "PAUSE_CONFIRM_YES": ("Yes, leave", "Evet, çık"),
    "PAUSE_CONFIRM_NO": ("Stay", "Kal"),
    "TOAST_FLOOR_CLEARED": ("Floor cleared · find the stairs", "Kat temizlendi · merdiveni bul"),
    "TOAST_CLEAR_FIRST": ("Clear the floor first", "Önce katı temizle"),
    "INV_TITLE": ("Inventory", "Envanter"),
    "INV_HINT": ("E CLOSE · RIGHT CLICK SELLS", "E KAPAT · SAĞ TIK SATAR"),
    "INV_WEAPON": ("WEAPON", "SİLAH"),
    "INV_HEAD": ("HEAD", "BAŞ"),
    "INV_CHEST": ("BODY", "GÖVDE"),
    "INV_FEET": ("FEET", "AYAK"),
    "INV_SELL": ("RIGHT CLICK: SELL FOR %d SOULS", "SAĞ TIK: %d RUHA SAT"),
    "INV_DELTA_DAMAGE": ("IF WORN: DAMAGE %.0f > %.0f", "GİYERSEN: HASAR %.0f > %.0f"),
    "INV_DELTA_DEFENSE": ("IF WORN: DEFENSE %.0f > %.0f", "GİYERSEN: SAVUNMA %.0f > %.0f"),
    "RARITY_COMMON": ("Common", "Sıradan"),
    "RARITY_UNCOMMON": ("Uncommon", "Nadide"),
    "RARITY_RARE": ("Rare", "Nadir"),
    "RARITY_EPIC": ("Epic", "Epik"),
    "RARITY_LEGENDARY": ("Legendary", "Efsanevi"),
    "STAT_DAMAGE": ("DAMAGE +%.0f", "HASAR +%.0f"),
    "STAT_ATTACK_SPEED": ("ATTACK SPEED x%.2f", "SALDIRI HIZI x%.2f"),
    "STAT_KNOCKBACK": ("KNOCKBACK +%.0f", "GERİ TEPME +%.0f"),
    "STAT_DEFENSE": ("DEFENSE +%.0f", "SAVUNMA +%.0f"),
    "STAT_LIFE": ("LIFE +%.0f", "CAN +%.0f"),
    "STAT_SPEED": ("SPEED +%.0f", "HIZ +%.0f"),
    "STAT_HEAL": ("HEALS %.0f LIFE", "%.0f CAN YENİLER"),
    "STAT_BUFF": ("BOOST +%.0f", "GÜÇ +%.0f"),
    # boon descriptions: %s is the number; percent signs are placed per language
    "UPG_DESC_DAMAGE_FLAT": ("+%s damage", "+%s hasar"),
    "UPG_DESC_DAMAGE_PERCENT": ("+%s%% damage", "+%%%s hasar"),
    "UPG_DESC_HEALTH_FLAT": ("+%s max life", "+%s azami can"),
    "UPG_DESC_SPEED_FLAT": ("+%s move speed", "+%s hareket hızı"),
    "UPG_DESC_ATTACK_SPEED": ("+%s%% attack speed", "+%%%s saldırı hızı"),
    "UPG_DESC_DEFENSE_FLAT": ("+%s defense", "+%s savunma"),
    "UPG_DESC_LIFE_STEAL": ("%s%% of the damage you deal returns as life.",
                            "Verdiğin hasarın %%%s kadarı can olarak döner."),
    "UPG_DESC_DASH_COOLDOWN": ("Dash recovers %s%% faster.", "Atılma %%%s daha çabuk dolar."),
    "UPG_DESC_HEALTH_PERCENT": ("+%s%% max life", "+%%%s azami can"),
    "UPG_DESC_SPEED_PERCENT": ("+%s%% move speed", "+%%%s hareket hızı"),
    "STORY_TITLE": ("Sunless Crown", "Güneşsiz Taç"),
    "STORY_BODY": (
        "Once, the kingdom of Aethelgard shone under a sun that never set.\n"
        "Then the King put on the Sunless Crown that slept in the deep.\n"
        "The crown promised him forever, and took the kingdom's light in return.\n"
        "The sun went out. The people turned to stone, the knights to shadow.\n"
        "You are the last ember, born from the ashes.\n"
        "Descend the nine floors the three Wardens guard. Break the crown, or become part of the dark.",
        "Bir zamanlar Aethelgard krallığı, güneşin hiç batmadığı topraklarda parlardı.\n"
        "Ta ki Kral, yeraltının derinliklerinde uyuyan Güneşsiz Taç'ı başına geçirene dek.\n"
        "Taç ona ölümsüzlük vaat etti — karşılığında krallığın ışığını aldı.\n"
        "Güneş söndü. Halk taşa, şövalyeler gölgeye döndü.\n"
        "Sen, küllerden doğan son alevsin.\n"
        "Üç Muhafız'ın koruduğu dokuz kata in. Taç'ı kır — ya da karanlığın bir parçası ol."),
}

BOSSES = {
    "GAROTH": {
        "NAME": ("Garoth", "Garoth"),
        "TITLE": ("The Broken Warden", "Kırık Muhafız"),
        "INTRO": ("Turn back, little flame. Past this threshold there is only a deeper dark.\n"
                  "The King ordered me to guard this door… and I still obey, even as my flesh rots.", ""),
        "DEFEAT": ("At last… my chains are broken. Thank you, mortal.\n"
                   "But those below are not as merciful as I was. Myrra's silence is waiting for you.", ""),
    },
    "MYRRA": {
        "NAME": ("Myrra", "Myrra"),
        "TITLE": ("Mother of Silence", "Sessizliğin Anası"),
        "INTRO": ("Your footsteps echoed all the way down here. A pity no one below will hear you scream.\n"
                  "Garoth was weak; he could still feel pity. I know no mercy.", ""),
        "DEFEAT": ("The silence… takes me at last. I see the Crown, hero…\n"
                   "it is calling you. I wonder if you can bear its whisper.", ""),
    },
    "VORLAK": {
        "NAME": ("King Vorlak", "Kral Vorlak"),
        "TITLE": ("Lord of the Sunless Crown", "Güneşsiz Taç'ın Efendisi"),
        "INTRO": ("So you are the last mortal to climb to my throne.\n"
                  "My kingdom turned to ash, my people to stone… yet here I remain, forever.\n"
                  "You too will be buried in this dark.", ""),
        "DEFEAT": ("The Crown… it falls from my head… After all these years… I feel the light again.\n"
                   "Perhaps this was the salvation. Let the curse end with you, hero.\n"
                   "Let the sun… rise… again.", ""),
    },
}

ITEMS = {
    "bone_fragment": ("Bone Fragment", "Loot worth a few souls."),
    "broadsword": ("Broadsword", "Wide, heavy strikes."),
    "flame_blade": ("Flame Blade", "Legendary burning steel."),
    "greater_potion": ("Greater Potion", "Restores a great deal of life."),
    "health_potion": ("Potion", "Restores some life."),
    "iron_armor": ("Iron Armor", "Solid protection for the body."),
    "iron_greaves": ("Iron Greaves", "Guarded legs."),
    "iron_helm": ("Iron Helm", "A sturdy helm."),
    "iron_sword": ("Iron Sword", "A reliable, balanced blade."),
    "leather_armor": ("Leather Armor", "Light but useful."),
    "leather_boots": ("Leather Boots", "Light and quick."),
    "leather_cap": ("Leather Cap", "Simple head protection."),
    "plate_armor": ("Plate Armor", "The heaviest guard; slows you a little."),
    "rusty_sword": ("Rusty Sword", "Old, but it still cuts."),
    "slime_goo": ("Slime Essence", "Sticky stuff slimes leave behind."),
    "steel_dagger": ("Steel Dagger", "Fast, with a short reach."),
    "war_hammer": ("War Hammer", "Heavy and slow; huge knockback."),
}

BOONS = {
    "attack_speed_plus": "Quick Hands", "berserk": "Berserk", "big_damage": "Keen Point",
    "big_health": "Sound Body", "damage_multiplier": "Blood Rage", "damage_plus": "Keen Edge",
    "dash_cooldown_reduce": "Shadow Step", "defense_plus": "Stone Skin", "fleet": "Wind Feet",
    "fortitude": "Fortitude", "glass_cannon": "Glass Cannon", "greater_lifesteal": "Bloodsucker",
    "health_plus": "Iron Heart", "huge_damage": "Deadly Force", "iron_skin": "Iron Skin",
    "juggernaut": "Juggernaut", "life_steal": "Vampiric Touch", "meta_attack_speed": "Lasting Fury",
    "meta_damage": "Lasting Might", "meta_defense": "Lasting Armor", "meta_health": "Lasting Vigor",
    "meta_speed": "Lasting Swiftness", "quick_dash": "Quick Dash", "sharpen": "Sharpen",
    "speed_plus": "Wind Step", "swift": "Swift", "vitality": "Vitality",
}


DATA = OUT.parents[1] / "data"
BOSS_FILES = {"GAROTH": "warden1_garoth", "MYRRA": "warden2_myrra", "VORLAK": "warden3_vorlak"}


def tres_str(path: Path, key: str) -> str:
    """A string field from a .tres file (the Turkish originals)."""
    import re
    s = path.read_text(encoding="utf-8")
    m = re.search(key + r' = "((?:[^"\\]|\\.)*)"', s, re.S)
    if not m:
        return ""
    return m.group(1).replace('\\"', '"').replace("\\n", "\n")


def main() -> None:
    rows = [("keys", "en", "tr")]
    for k, (en, tr) in UI.items():
        rows.append((k, en, tr))
    for b, parts in BOSSES.items():
        f = DATA / "bosses" / f"{BOSS_FILES[b]}.tres"
        for part, (en, tr) in parts.items():
            if not tr:
                tr = tres_str(f, {"INTRO": "intro_text", "DEFEAT": "defeat_text"}[part])
            rows.append((f"BOSS_{b}_{part}", en, tr))
    for i, (name, desc) in ITEMS.items():
        f = DATA / "items" / f"{i}.tres"
        rows.append((f"ITEM_{i.upper()}_NAME", name, tres_str(f, "display_name")))
        rows.append((f"ITEM_{i.upper()}_DESC", desc, tres_str(f, "description")))
    for u, name in BOONS.items():
        rows.append((f"UPG_{u.upper()}_NAME", name, tres_str(DATA / "upgrades" / f"{u}.tres", "display_name")))
    missing = [r[0] for r in rows[1:] if not r[1] or not r[2]]
    assert not missing, f"untranslated: {missing}"
    OUT.parent.mkdir(exist_ok=True)
    with OUT.open("w", encoding="utf-8", newline="") as f:
        csv.writer(f, lineterminator="\n").writerows(rows)
    print(f"{len(rows) - 1} keys -> {OUT}")


if __name__ == "__main__":
    main()
