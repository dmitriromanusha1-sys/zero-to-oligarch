extends Node2D

const BuildingScene       = preload("res://scenes/Building.tscn")
const NPCScene            = preload("res://scenes/NPC.tscn")
const CriminalJobScript   = preload("res://scripts/CriminalJob.gd")
const FoodShopScene       = preload("res://scenes/FoodShop.tscn")
const NewspaperScene      = preload("res://scenes/Newspaper.tscn")
const EducationShopScene  = preload("res://scenes/EducationShop.tscn")
const TravelAgencyUIScene  = preload("res://scenes/TravelAgencyUI.tscn")
const BusStopUIScene       = preload("res://scenes/BusStopUI.tscn")
const TransportShopUIScene = preload("res://scenes/TransportShopUI.tscn")
const BusStopScript       = preload("res://scripts/BusStop.gd")

# ─── Спрайты из тайлсета ─────────────────────────────────────────────────────
const TEX_TREE_BIG   = preload("res://tiles/Vegetation/tree_big 128x128.png")
const TEX_TREE_MINI  = preload("res://tiles/Vegetation/minitree32x48.png")
const TEX_BUSH       = preload("res://tiles/Vegetation/bush.png")
const TEX_TRASHCAN   = preload("res://tiles/Tilemaps & Additive Env/trashcan32x32.png")
const TEX_BUILDING      = preload("res://tiles/building-red-01.png")
const TEX_HOUSE_PANEL9  = preload("res://assets/textures/House panel 9.png")
const TEX_HOUSE_KHRUSH  = preload("res://assets/textures/House khrushchevka.png")
const TEX_HOUSE_BRICK5  = preload("res://assets/textures/House brick 5.png")
const TEX_HOUSE_BARAK   = preload("res://assets/textures/House barak.png")

# ─── Текстуры жилых зданий по зонам (для декоративных домов) ────────────────
const ZONE_HOUSE_TEX: Array = [
	"res://assets/textures/house_zone0_barak.png",
	"res://assets/textures/house_zone1_kommunalka.png",
	"res://assets/textures/house_zone2_khrushchevka.png",
	"res://assets/textures/house_zone3_panel9.png",
	"res://assets/textures/house_zone4_modern.png",
	"res://assets/textures/house_zone5_elite.png",
	"res://assets/textures/house_zone6_villa.png",
	"res://assets/textures/house_zone7_gov.png",
	"res://assets/textures/house_zone8_palace.png",
]

const TEX_CAR_SEDAN  = preload("res://tiles/cars/sedan-car-76x76.png")
const TEX_CAR_MINI   = preload("res://tiles/cars/mini-car-76x76.png")
const TEX_CAR_MUSCLE = preload("res://tiles/cars/muscle-car-76x76.png")
const TEX_CONE       = preload("res://tiles/Road Signs/cone.png")
const TEX_HYDRANT    = preload("res://tiles/Tilemaps & Additive Env/hydrant 32x32.png")


# ─── Константы карты ─────────────────────────────────────────────────────────
const ZONE_SIZE: float = 2500.0  # размер одной зоны
const MAP_HALF:  float = 3750.0  # полкарты (3 зоны × 2500 / 2)

# ─── Базовый цвет земли по зонам (сплошная заливка, без швов мозаики) ────────
const GROUND_BASE_COLORS: Array = [
	Color(0.62, 0.55, 0.42),  # 0 — Трущобы (потёртая плитка/бетон)
	Color(0.40, 0.32, 0.22),  # 1 — Рабочий квартал  (грязь/земля)
	Color(0.30, 0.46, 0.26),  # 2 — Спальный район   (трава)
	Color(0.64, 0.58, 0.46),  # 3 — Средний класс    (плитка)
	Color(0.60, 0.60, 0.62),  # 4 — Бизнес-квартал   (плитка/асфальт)
	Color(0.80, 0.79, 0.76),  # 5 — Элитный район    (мрамор)
	Color(0.82, 0.80, 0.74),  # 6 — Район олигархов  (мрамор)
	Color(0.78, 0.78, 0.80),  # 7 — Правительственный (мрамор)
	Color(0.84, 0.82, 0.78),  # 8 — Высший свет       (мрамор)
]


# ─── Автобусные остановки (по одной у каждой зоны) ──────────────────────────
const BUS_STOPS: Array = [
	{"name":"🚌 Трущобы","pos":Vector2(-2500, -2420)},
	{"name":"🚌 Рабочий кв.",   "pos":Vector2(    0, -2420)},
	{"name":"🚌 Спальный р.",   "pos":Vector2( 2500, -2420)},
	{"name":"🚌 Средний класс", "pos":Vector2( 2420,     0)},
	{"name":"🚌 Центральная",   "pos":Vector2(    0,    80)},
	{"name":"🚌 Элитный р.",    "pos":Vector2(-2420,     0)},
	{"name":"🚌 Олигархи",      "pos":Vector2(-2500,  2420)},
	{"name":"🚌 Прав. кв.",     "pos":Vector2(    0,  2420)},
	{"name":"🚌 Высший свет",   "pos":Vector2( 2500,  2420)},
]

# ─── Данные зданий для каждой зоны (позиции относительно центра зоны) ────────
const ZONE_BUILDINGS: Array = [

	# ── Зона 0: Трущобы ──────────────────────────────────────────────────────────
	[
		# ── Административный север ──────────────────────────────────────────────────
		{"name":"🏫 Школа",              "action":"Получить образование",            "reward":0,   "cd":999,  "pos":Vector2(-350,-880), "color":Color(0.24,0.32,0.52), "edu_shop":true, "edu_max":2, "tex":"res://assets/textures/Shcolla.png"},
		{"name":"🏢 ЖЭК",               "action":"Открыть бизнес",                  "reward":0,   "cd":999,  "pos":Vector2( 500,-880), "color":Color(0.38,0.35,0.28), "biz":true,                   "tex":"res://assets/textures/Nalogovaa.png"},
		{"name":"💊 Аптека",             "action":"Купить лекарства (+20 здоровья)", "reward":0,   "cd":8.0,  "pos":Vector2(-900,-580), "color":Color(0.12,0.48,0.32), "heal":20,                    "tex":"res://assets/textures/apteka 0.png"},
		# ── Западный проспект ───────────────────────────────────────────────────────
		{"name":"🏦 Банк",               "action":"Банк и бизнес",                   "reward":0,   "cd":999,  "pos":Vector2(-900,  80), "color":Color(0.10,0.28,0.55), "biz":true,                   "tex":"res://assets/textures/Sber bank.png"},
		# ── Торговая улица ──────────────────────────────────────────────────────────
		{"name":"🏪 Продукты «24»",      "action":"Работать грузчиком (+250 ₽)",     "reward":250, "cd":3.0,  "pos":Vector2(-480, 100), "color":Color(0.72,0.08,0.08), "minigame":true, "heavy":true, "edu_req":1, "food_shop":"🏪 Продукты «24»", "food_items":["bread","hotdog","water","kvas","tea","vitamins","bandage"], "tex":"res://assets/textures/Paterochka.png"},
		{"name":"🍖 Шаурмячная",         "action":"Готовить шаурму (+150 ₽)",        "reward":150, "cd":2.5,  "pos":Vector2( 180, 100), "color":Color(0.52,0.28,0.10), "minigame":true, "edu_req":1, "food_shop":"🍖 Шаурмячная", "food_items":["shawarma","hotdog","soup","kvas","juice","meal_cheap"], "tex":"res://assets/textures/Shaverma.png"},
		{"name":"🏥 Поликлиника",        "action":"Пройти осмотр (+25 здоровья)",    "reward":0,   "cd":10.0, "pos":Vector2( 820, 100), "color":Color(0.18,0.45,0.50), "heal":25,                    "tex":"res://assets/textures/Poliklinika.png"},
		# ── Центральный хаб ─────────────────────────────────────────────────────────
		{"name":"🚌 Автовокзал",         "action":"Уехать в другой район",           "reward":0,   "cd":999,  "pos":Vector2(   0, 320), "color":Color(0.16,0.26,0.46), "travel":true,                "tex":"res://assets/textures/Avtovoczal.png"},
		# ── Начальная работа (дворы) ────────────────────────────────────────────────
		{"name":"🗑 Мусорные баки",      "action":"Собирать бутылки (+160 ₽)",       "reward":160, "cd":2.0,  "pos":Vector2(-850, 720), "color":Color(0.28,0.26,0.20), "minigame":true, "heavy":true, "tex":"res://assets/textures/trash_bins.png"},
		{"name":"🧹 Подъезды",           "action":"Работать дворником (+130 ₽)",     "reward":130, "cd":1.5,  "pos":Vector2(-200, 680), "color":Color(0.40,0.35,0.28), "minigame":true, "heavy":true, "tex":"res://assets/textures/podyezd.png"},
		{"name":"🍺 Ларёк «Уют»",        "action":"Подработать в ларьке (+110 ₽)",   "reward":110, "cd":1.5,  "pos":Vector2( 350, 680), "color":Color(0.48,0.32,0.12), "minigame":true, "food_shop":"🍺 Ларёк «Уют»", "food_items":["bread","water","kvas","tea","pills"], "tex":"res://assets/textures/laryok.png"},
		# ── Стройка (северо-восток) ─────────────────────────────────────────────────
		{"name":"🏗 Стройка",            "action":"Разнорабочий (+400 ₽)",           "reward":400, "cd":4.0,  "pos":Vector2( 900,-480), "color":Color(0.40,0.32,0.18), "minigame":true, "heavy":true, "edu_req":2, "tex":"res://assets/textures/Stroika.png"},
	],

	# ── Зона 1: Рабочий квартал ───────────────────────────────────────────────
	[
		# ── Промзона (север) ──────────────────────────────────────────────────────
		{"name":"🏭 Завод «ГлавПром»",  "action":"Рабочий завода (+1 100 ₽)",     "reward":1100, "cd":5.0,  "pos":Vector2(-900,-350), "color":Color(0.28,0.28,0.38), "minigame":true, "heavy":true, "edu_req":3, "tex":"res://assets/textures/Factory.png"},
		{"name":"🏗 Стройка «Монолит»", "action":"Работать строителем (+800 ₽)",  "reward":800,  "cd":4.0,  "pos":Vector2( 700,-400), "color":Color(0.45,0.35,0.20), "minigame":true, "heavy":true, "edu_req":3, "tex":"res://assets/textures/Stroika.png"},
		{"name":"🚛 Склад №7",          "action":"Грузчик / экспедитор (+950 ₽)", "reward":950,  "cd":4.5,  "pos":Vector2( 300,-600), "color":Color(0.28,0.28,0.32), "minigame":true, "heavy":true, "edu_req":3, "tex":"res://assets/textures/sklad.png"},
		# ── Торговая улица (центр) ────────────────────────────────────────────────
		{"name":"🏪 Рынок «Удача»",     "action":"Продавец на рынке (+600 ₽)",    "reward":600,  "cd":3.0,  "pos":Vector2(-600, 450), "color":Color(0.40,0.50,0.18), "minigame":true, "edu_req":2, "tex":"res://assets/textures/Rynok.png"},
		{"name":"🔧 Авторемонт",        "action":"Работать автомехаником (+1 600 ₽)", "reward":1600, "cd":6.0,  "pos":Vector2( 900, 300), "color":Color(0.42,0.30,0.18), "minigame":true, "heavy":true, "edu_req":4, "tex":"res://assets/textures/Avtomasterskaa.png"},
		{"name":"🍺 Пивная «Факел»",    "action":"Купить еду и напитки",          "reward":0,    "cd":999,  "pos":Vector2(-300, 600), "color":Color(0.50,0.28,0.08), "food_shop":"🍺 Пивная «Факел»", "food_items":["bread","hotdog","water","kvas","tea","pills","bandage","meal_canteen"], "tex":"res://assets/textures/pivnaya.png"},
		# ── Социальная инфраструктура (запад) ─────────────────────────────────────
		{"name":"🏥 Медпункт",          "action":"Первая помощь (+20 здоровья)",  "reward":0,    "cd":8.0,  "pos":Vector2(-900, 200), "color":Color(0.18,0.48,0.45), "heal":20, "tex":"res://assets/textures/medpunkt.png"},
		{"name":"🏦 Банк «Труд»",       "action":"Открыть меню банка",            "reward":0,    "cd":999,  "pos":Vector2( 500,-600), "color":Color(0.20,0.38,0.60), "biz":true, "tex":"res://assets/textures/Sber bank.png"},
		{"name":"🏛 Биржа труда",       "action":"Открыть бизнес",                "reward":0,    "cd":999,  "pos":Vector2(-500,-600), "color":Color(0.48,0.44,0.20), "biz":true, "tex":"res://assets/textures/Nalogovaa.png"},
		# ── Образование ───────────────────────────────────────────────────────────
		{"name":"📝 Средняя школа",     "action":"Получить образование",          "reward":0,    "cd":999,  "pos":Vector2(-900, 500), "color":Color(0.22,0.28,0.42), "edu_shop":true, "edu_max":3, "tex":"res://assets/textures/Shcolla.png"},
		{"name":"⚙ ПТУ «Политех»",     "action":"Получить образование (ПТУ)",    "reward":0,    "cd":999,  "pos":Vector2( 900,-500), "color":Color(0.28,0.25,0.38), "edu_shop":true, "edu_max":4, "tex":"res://assets/textures/Shcolla.png"},
		# ── Транспорт ─────────────────────────────────────────────────────────────
		{"name":"✈ Тур.фирма",          "action":"Переехать в следующий район",   "reward":0,    "cd":999,  "pos":Vector2(  0, 250), "color":Color(0.15,0.30,0.50), "travel":true, "tex":"res://assets/textures/Travel agency office.png"},
	],

	# ── Зона 2: Спальный район «Северный» ───────────────────────────────────────
	[
		{"name":"☕ Кафе «Берёзка»",        "action":"Работать бариста (+2 800 ₽)",     "reward":2800, "cd":5.0,  "pos":Vector2(-800,-300), "color":Color(0.50,0.35,0.25), "minigame":true, "edu_req":4, "food_shop":"☕ Кафе «Берёзка»", "food_items":["pie","soup","burger","coffee","juice","tea","smoothie","vitamins","meal_cafe"], "tex":"res://assets/textures/Cafe.png"},
		{"name":"🍕 Пиццерия «Итальяно»",   "action":"Курьер пиццерии (+2 000 ₽)",      "reward":2000, "cd":3.5,  "pos":Vector2(-200,-350), "color":Color(0.55,0.28,0.18), "minigame":true, "edu_req":4, "food_shop":"🍕 Пиццерия «Итальяно»", "food_items":["pizza_margherita","pizza_pepperoni","pizza_hawaii","pizza_quattro","cocktail","juice","coffee","water"], "tex":"res://assets/textures/pizzeria.png"},
		{"name":"🛒 Супермаркет «Магнит»",  "action":"Работать кассиром (+2 400 ₽)",    "reward":2400, "cd":4.0,  "pos":Vector2( 700, 350), "color":Color(0.25,0.45,0.35), "minigame":true, "edu_req":4, "food_shop":"🛒 Супермаркет", "food_items":["bread","hotdog","burger","pizza","water","juice","coffee","tea","smoothie","bandage","pills","medkit","vitamins"], "tex":"res://assets/textures/Supermarket.png"},
		{"name":"🏥 Поликлиника №5",        "action":"Пройти осмотр (+35 здоровья)",    "reward":0,    "cd":10.0, "pos":Vector2(-900, 400), "color":Color(0.30,0.55,0.55), "heal":35,        "tex":"res://assets/textures/Poliklinika.png"},
		{"name":"💊 Аптека «36.6»",         "action":"Купить лекарства (+15 здоровья)", "reward":0,    "cd":5.0,  "pos":Vector2( 800, 400), "color":Color(0.18,0.58,0.42), "heal":15, "tex":"res://assets/textures/apteka_366.png"},
		{"name":"🏋 Фитнес-центр «Энергия»","action":"Тренировка (+25 здоровья)",       "reward":0,    "cd":8.0,  "pos":Vector2( 600,-600), "color":Color(0.25,0.40,0.35), "heal":25,        "tex":"res://assets/textures/Sport club.png"},
		{"name":"🏦 ВТБ Банк",              "action":"Открыть меню банка",              "reward":0,    "cd":999,  "pos":Vector2(-500,-600), "color":Color(0.20,0.40,0.60), "biz":true,       "tex":"res://assets/textures/Sber bank.png"},
		{"name":"📋 Колледж «Ломоносов»",   "action":"Получить образование",            "reward":0,    "cd":999,  "pos":Vector2(-700, 600), "color":Color(0.25,0.30,0.48), "edu_shop":true,  "edu_max":5, "tex":"res://assets/textures/Univerciti.png"},
		{"name":"🎭 Кинотеатр «Октябрь»",   "action":"Работать киномехаником (+3 600 ₽)", "reward":3600, "cd":3.5,  "pos":Vector2( 500, 600), "color":Color(0.38,0.22,0.48), "minigame":true,  "edu_req":5, "tex":"res://assets/textures/kinoteatr.png"},
		{"name":"✈ Тур.агентство",          "action":"Переехать в следующий район",     "reward":0,    "cd":999,  "pos":Vector2(  0, 250), "color":Color(0.15,0.30,0.50), "travel":true,    "tex":"res://assets/textures/Travel agency office.png"},
	],

	# ── Зона 3: Средний класс ─────────────────────────────────────────────────
	[
		{"name":"🏦 Инвест. банк",   "action":"Работать финансистом (+8 000 ₽)", "reward":8000,  "cd":7.0,  "pos":Vector2(-800,-300), "color":Color(0.20,0.40,0.55), "minigame":true, "edu_req":6, "tex":"res://assets/textures/Bank investment.png"},
		{"name":"🚘 Автосервис",     "action":"Работать менеджером по продажам (+6 000 ₽)",  "reward":6000,  "cd":6.0,  "pos":Vector2( 800, 400), "color":Color(0.45,0.35,0.25), "minigame":true, "edu_req":5, "tex":"res://assets/textures/Avtomasterskaa.png"},
		{"name":"🏋 Фитнес-клуб",    "action":"Тренировка (+20 здоровья)",      "reward":0,     "cd":8.0,  "pos":Vector2(-600, 500), "color":Color(0.25,0.40,0.35), "heal":20,   "tex":"res://assets/textures/Sport club.png"},
		{"name":"🍽 Ресторан",       "action":"Работать в ресторане (+4 500 ₽)", "reward":4500,  "cd":5.0,  "pos":Vector2( 700,-500), "color":Color(0.55,0.35,0.20), "minigame":true, "food_shop":"🍽 Ресторан", "food_items":["pizza","sushi","steak","smoothie","cocktail","elite_medkit","meal_restaurant"], "edu_req":5, "tex":"res://assets/textures/Restoran.png"},
		{"name":"🏛 Налоговая",      "action":"Открыть бизнес",                 "reward":0,     "cd":999,  "pos":Vector2( 500,-600), "color":Color(0.50,0.45,0.20), "biz":true,  "tex":"res://assets/textures/Nalogovaa.png"},
		{"name":"🏫 Университет",    "action":"Получить образование (бакалавр)","reward":0,     "cd":999,  "pos":Vector2(-900, 500), "color":Color(0.30,0.35,0.50), "edu_shop":true, "edu_max":6, "tex":"res://assets/textures/Univerciti.png"},
		{"name":"✈ Тур.фирма",       "action":"Переехать в следующий район",    "reward":0,     "cd":999,  "pos":Vector2(  0, 250), "color":Color(0.15,0.30,0.50), "travel":true, "tex":"res://assets/textures/Travel agency office.png"},
	],

	# ── Зона 4: Бизнес-квартал ───────────────────────────────────────────────
	[
		{"name":"📈 Биржа",           "action":"Открыть торговую платформу",      "reward":0,     "cd":999,  "pos":Vector2(-800,-300), "color":Color(0.20,0.35,0.55), "stock":true,    "edu_req":6, "tex":"res://assets/textures/Birza.png"},
		{"name":"🏢 Офис-центр",      "action":"Работать менеджером (+18 000 ₽)", "reward":18000, "cd":5.0,  "pos":Vector2( 700,-400), "color":Color(0.25,0.30,0.45), "minigame":true, "edu_req":6, "tex":"res://assets/textures/Office.png"},
		{"name":"💻 Технопарк",       "action":"Разработчик стартапа (+24 000 ₽)", "reward":24000, "cd":6.0,  "pos":Vector2(-200,-700), "color":Color(0.18,0.32,0.52), "minigame":true, "edu_req":7, "tex":"res://assets/textures/Office.png"},
		{"name":"💹 Торговый зал",    "action":"Работать трейдером (+15 000 ₽)",  "reward":15000, "cd":4.0,  "pos":Vector2( 600,-200), "color":Color(0.22,0.38,0.58), "minigame":true, "edu_req":6, "tex":"res://assets/textures/Birza.png"},
		{"name":"🎯 Венчурный фонд",  "action":"Венчурный инвестор (+30 000 ₽)",  "reward":30000, "cd":14.0, "pos":Vector2( 800,-600), "color":Color(0.28,0.22,0.52), "minigame":true, "edu_req":7, "tex":"res://assets/textures/Board of directors.png"},
		{"name":"🏛 Конгресс-холл",   "action":"Организатор конференций (+13 000 ₽)", "reward":13000, "cd":8.0,  "pos":Vector2(-800, 400), "color":Color(0.28,0.36,0.56), "minigame":true, "edu_req":6, "tex":"res://assets/textures/Board of directors.png"},
		{"name":"☕ Бизнес-кафе",     "action":"Работать в бизнес-кафе (+10 000 ₽)", "reward":10000, "cd":3.0,  "pos":Vector2(-250,-150), "color":Color(0.42,0.28,0.18), "minigame":true, "edu_req":6, "food_shop":"☕ Бизнес-кафе", "food_items":["coffee","pie","burger","smoothie","juice","vitamins","meal_business"], "tex":"res://assets/textures/Cafe.png"},
		{"name":"🍽 Ресторан",        "action":"Работать в ресторане (+11 000 ₽)", "reward":11000, "cd":5.0,  "pos":Vector2(-600, 500), "color":Color(0.55,0.35,0.20), "minigame":true, "edu_req":6, "food_shop":"🍽 Ресторан", "food_items":["pizza","sushi","steak","smoothie","cocktail","elite_medkit","meal_business"], "tex":"res://assets/textures/Restoran.png"},
		{"name":"🏋 Фитнес Premium",  "action":"Тренировка (+40 здоровья)",       "reward":0,     "cd":8.0,  "pos":Vector2( 300, 650), "color":Color(0.22,0.40,0.38), "heal":40,        "tex":"res://assets/textures/Sport club.png"},
		{"name":"🏛 Мэрия",           "action":"Открыть бизнес",                  "reward":0,     "cd":999,  "pos":Vector2( 500,-600), "color":Color(0.50,0.50,0.30), "biz":true,        "tex":"res://assets/textures/Meria.png"},
		{"name":"🏥 Клиника",         "action":"Лечиться (+45 здоровья)",         "reward":0,     "cd":10.0, "pos":Vector2( 800, 400), "color":Color(0.30,0.55,0.55), "heal":45,         "tex":"res://assets/textures/Poliklinika.png"},
		{"name":"🎓 Магистратура",    "action":"Получить образование (магистр)",  "reward":0,     "cd":999,  "pos":Vector2(-900, 500), "color":Color(0.20,0.28,0.50), "edu_shop":true,   "edu_max":7, "tex":"res://assets/textures/Univerciti.png"},
		{"name":"✈ Тур.фирма",        "action":"Переехать в следующий район",     "reward":0,     "cd":999,  "pos":Vector2(  0, 250),  "color":Color(0.15,0.30,0.50), "travel":true, "tex":"res://assets/textures/Travel agency office.png"},
	],

	# ── Зона 5: Элитный район ─────────────────────────────────────────────────
	[
		{"name":"🛥 Яхт-клуб",       "action":"Менеджер яхт-клуба (+40 000 ₽)", "reward":40000, "cd":10.0, "pos":Vector2(-800,-300), "color":Color(0.15,0.30,0.50), "minigame":true, "edu_req":7, "tex":"res://assets/textures/Yacht club.png"},
		{"name":"✈ Аэропорт",        "action":"Деловой рейс за границу (+150 000 ₽)", "reward":150000,"cd":20.0, "pos":Vector2( 700,-400), "color":Color(0.30,0.30,0.50), "minigame":true, "edu_req":8, "tex":"res://assets/textures/Private airport.png"},
		{"name":"🎰 Казино",         "action":"Сыграть в казино (±50 000 ₽)",   "reward":50000, "cd":5.0,  "pos":Vector2(-500, 500), "color":Color(0.50,0.20,0.40), "casino":true, "tex":"res://assets/textures/Casino.png"},
		{"name":"🏡 Агентство недвижимости", "action":"Доходная недвижимость",      "reward":0,     "cd":999,  "pos":Vector2( 500,-600), "color":Color(0.30,0.45,0.30), "realestate":true, "tex":"res://assets/textures/Office.png"},
		{"name":"🥂 VIP-Ресторан",  "action":"Гастрономический ужин",          "reward":0,     "cd":999,  "pos":Vector2( 700, 600), "color":Color(0.50,0.28,0.38), "food_shop":"🥂 VIP-Ресторан", "food_items":["steak","sushi","cocktail","smoothie","elite_medkit","meal_elite"], "tex":"res://assets/textures/Restoran.png"},
		{"name":"🏥 Частная клиника","action":"Лечиться (+50 здоровья)",        "reward":0,     "cd":10.0, "pos":Vector2( 800, 400), "color":Color(0.30,0.55,0.55), "heal":50,   "tex":"res://assets/textures/Poliklinika.png"},
		{"name":"🔬 Аспирантура",    "action":"Получить образование (аспирант)","reward":0,     "cd":999,  "pos":Vector2(-900, 500), "color":Color(0.18,0.25,0.45), "edu_shop":true, "edu_max":8, "tex":"res://assets/textures/Univerciti.png"},
		{"name":"📻 Магазин радио", "action":"Выбрать радиостанцию",            "reward":0,     "cd":999,  "pos":Vector2(-200,-600), "color":Color(0.45,0.25,0.50), "radio_shop":true},
		{"name":"✈ Тур.фирма",       "action":"Переехать в следующий район",    "reward":0,     "cd":999,  "pos":Vector2(  0, 250), "color":Color(0.15,0.30,0.50), "travel":true, "tex":"res://assets/textures/Travel agency office.png"},
	],

	# ── Зона 6: Район олигархов ───────────────────────────────────────────────
	[
		{"name":"🏰 Дворец",         "action":"Приём гостей (+900 000 ₽)",      "reward":900000,  "cd":30.0, "pos":Vector2(-800,-300), "color":Color(0.50,0.45,0.15), "minigame":true, "edu_req":8, "tex":"res://assets/textures/Oligarch's palace.png"},
		{"name":"🛩 Частный аэропорт","action":"Деловой рейс (+2 млн ₽)",       "reward":2000000, "cd":40.0, "pos":Vector2( 700,-400), "color":Color(0.25,0.25,0.40), "minigame":true, "edu_req":9, "tex":"res://assets/textures/Private airport.png"},
		{"name":"🛢 Нефтяная вышка", "action":"Качать нефть (+600 000 ₽)",      "reward":600000,  "cd":60.0, "pos":Vector2(-600, 500), "color":Color(0.20,0.20,0.20), "minigame":true, "heavy":true, "edu_req":8, "tex":"res://assets/textures/Oil derrick industrial facility.png"},
		{"name":"🎭 Опера",          "action":"Работать в опере (+200 000 ₽)",   "reward":200000,  "cd":15.0, "pos":Vector2( 700, 500), "color":Color(0.40,0.25,0.45), "minigame":true, "edu_req":8, "tex":"res://assets/textures/Opera house building.png"},
		{"name":"🍾 Ресторан Мишлен","action":"Обед от шефа",                   "reward":0,       "cd":999,  "pos":Vector2(-400, 700), "color":Color(0.55,0.30,0.15), "food_shop":"🍾 Ресторан Мишлен", "food_items":["steak","sushi","cocktail","smoothie","elite_medkit","meal_michelin"], "tex":"res://assets/textures/Restoran.png"},
		{"name":"🏦 Офшор",          "action":"Перевести деньги в офшор",        "reward":0,       "cd":999,  "pos":Vector2( 500,-600), "color":Color(0.20,0.35,0.50), "biz":true, "tex":"res://assets/textures/Generic bank branch building.png"},
		{"name":"🧠 НИИ (Наука)",    "action":"Получить образование (гений)",    "reward":0,       "cd":999,  "pos":Vector2(-900, 500), "color":Color(0.15,0.20,0.40), "edu_shop":true, "edu_max":10, "tex":"res://assets/textures/NIИ.png"},
		{"name":"🎰 Казино VIP",     "action":"Сыграть в казино (±500 000 ₽)",   "reward":500000,  "cd":5.0,  "pos":Vector2(-400,-500), "color":Color(0.55,0.22,0.45), "casino":true, "tex":"res://assets/textures/Casino.png"},
		{"name":"🏥 Госпиталь «Олимп»","action":"Лечение (+55 здоровья)",        "reward":0,       "cd":11.0, "pos":Vector2( 900, 200), "color":Color(0.28,0.52,0.52), "heal":55, "tex":"res://assets/textures/Medical clinic building.png"},
		{"name":"🏛 Политический клуб","action":"Власть и влияние",               "reward":0,       "cd":999,  "pos":Vector2(-150, -600), "color":Color(0.38,0.28,0.50), "influence":true, "tex":"res://assets/textures/Meria.png"},
		{"name":"✈ Тур.фирма",       "action":"Переехать в следующий район",     "reward":0,       "cd":999,  "pos":Vector2(   0,  250), "color":Color(0.15,0.30,0.50), "travel":true, "tex":"res://assets/textures/Travel agency office.png"},
	],

	# ── Зона 7: Правительственный квартал ─────────────────────────────────────
	[
		{"name":"🏛 Минфин",          "action":"Госконтракт (+5 млн ₽)",         "reward":5000000, "cd":25.0, "pos":Vector2(-800,-300), "color":Color(0.28,0.32,0.50), "minigame":true, "edu_req":10, "tex":"res://assets/textures/Russian Ministry of Finance building.png"},
		{"name":"🏦 Госбанк",         "action":"Открыть счёт",                   "reward":0,       "cd":999,  "pos":Vector2( 700,-400), "color":Color(0.18,0.28,0.55), "biz":true, "tex":"res://assets/textures/Generic bank branch building.png"},
		{"name":"🤝 Посольство",      "action":"Контракт (+9 млн ₽)",            "reward":9000000, "cd":30.0, "pos":Vector2(-600, 500), "color":Color(0.32,0.38,0.55), "minigame":true, "edu_req":10, "tex":"res://assets/textures/Embassy building.png"},
		{"name":"💼 Совет директоров","action":"Заседание (+2,5 млн ₽)",         "reward":2500000, "cd":20.0, "pos":Vector2( 700, 500), "color":Color(0.25,0.30,0.48), "minigame":true, "edu_req":10, "tex":"res://assets/textures/Board of directors.png"},
		{"name":"🏥 VIP-Клиника",     "action":"Лечение (+60 здоровья)",         "reward":0,       "cd":12.0, "pos":Vector2( 900, 300), "color":Color(0.25,0.50,0.50), "heal":60, "tex":"res://assets/textures/Medical clinic building.png"},
		{"name":"🔬 Академия наук",   "action":"Получить образование (гений)",   "reward":0,       "cd":999,  "pos":Vector2(-900, 500), "color":Color(0.15,0.20,0.40), "edu_shop":true, "edu_max":10, "tex":"res://assets/textures/Academy of sciences.png"},
		{"name":"🏛 Налог.служба",    "action":"Открыть бизнес",                 "reward":0,       "cd":999,  "pos":Vector2( 500,-600), "color":Color(0.42,0.40,0.18), "biz":true, "tex":"res://assets/textures/Nalogovaa.png"},
		{"name":"🍽 Дом приёмов",     "action":"Банкетный стол",                 "reward":0,       "cd":999,  "pos":Vector2( 300, 300), "color":Color(0.45,0.30,0.20), "food_shop":"🍽 Дом приёмов", "food_items":["steak","sushi","cocktail","smoothie","elite_medkit","meal_reception"], "tex":"res://assets/textures/Restoran.png"},
		{"name":"✈ Тур.фирма",        "action":"Переехать в следующий район",    "reward":0,       "cd":999,  "pos":Vector2(   0,  250), "color":Color(0.15,0.30,0.50), "travel":true, "tex":"res://assets/textures/Travel agency office.png"},
	],

	# ── Зона 8: Высший свет (ФИНАЛ) ──────────────────────────────────────────
	[
		{"name":"🛢 Нефтекорпорация", "action":"Нефтяная сделка (+25 млн ₽)",   "reward":25000000, "cd":45.0, "pos":Vector2(-800,-300), "color":Color(0.18,0.18,0.25), "minigame":true, "edu_req":10, "tex":"res://assets/textures/Oil derrick industrial facility.png"},
		{"name":"📡 Медиа-империя",   "action":"Медиасделка (+12 млн ₽)",        "reward":12000000, "cd":35.0, "pos":Vector2( 700,-400), "color":Color(0.22,0.22,0.32), "minigame":true, "edu_req":10, "tex":"res://assets/textures/Media empire.png"},
		{"name":"📜 Госконтракт",     "action":"Тендер (+60 млн ₽)",             "reward":60000000, "cd":60.0, "pos":Vector2(-600, 500), "color":Color(0.20,0.20,0.30), "minigame":true, "edu_req":10, "tex":"res://assets/textures/Gov contract.png"},
		{"name":"🎰 Казино-Роял",     "action":"Играть (±2 млн ₽)",              "reward":2000000,  "cd":5.0,  "pos":Vector2( 700, 500), "color":Color(0.50,0.18,0.42), "casino":true, "tex":"res://assets/textures/Royal casino Casino-Royal.png"},
		{"name":"🏦 Частный банк",    "action":"Управление капиталом",            "reward":0,        "cd":999,  "pos":Vector2( 500,-600), "color":Color(0.16,0.24,0.48), "biz":true, "tex":"res://assets/textures/Generic bank branch building.png"},
		{"name":"🏥 Медцентр",        "action":"Лечение (+80 здоровья)",         "reward":0,        "cd":12.0, "pos":Vector2( 900, 300), "color":Color(0.22,0.48,0.48), "heal":80, "tex":"res://assets/textures/Medical clinic building.png"},
		{"name":"🧠 НИИ Элит",        "action":"Получить образование (гений)",   "reward":0,        "cd":999,  "pos":Vector2(-900, 500), "color":Color(0.10,0.15,0.35), "edu_shop":true, "edu_max":10, "tex":"res://assets/textures/NIИ.png"},
		{"name":"🥂 Императорский зал","action":"Приём гостей",                  "reward":0,        "cd":999,  "pos":Vector2( 300, 300), "color":Color(0.48,0.30,0.22), "food_shop":"🥂 Императорский зал", "food_items":["steak","sushi","cocktail","smoothie","elite_medkit","meal_imperial"], "tex":"res://assets/textures/Restoran.png"},
		{"name":"✈ Тур.фирма",        "action":"Переехать на Остров",            "reward":0,        "cd":999,  "pos":Vector2(   0,  250), "color":Color(0.15,0.30,0.50), "travel":true, "tex":"res://assets/textures/Travel agency office.png"},
	],
]

# ─── NPC по зонам ────────────────────────────────────────────────────────────
const ZONE_NPC: Array = [
	[
		{"name":"🧔 Дядя Коля",   "pos":Vector2(-200, 420), "lines":["Слышь, земляк, в «Продуктах» грузчики нужны. Иди попробуй.", "В «Заре» живу уже 30 лет. Всё меняется, а панельки стоят.", "Шаурму тут берёшь? Нормальная, не отравишься почти."], "title_lines":[
			["Слышь, земляк, в «Продуктах» грузчики нужны. Иди попробуй."],
			["Видел что ли как ты бутылки собирал. Не сдавайся, брат."],
			["Ты ж теперь при деньгах? Дай на пиво, земляк!"],
			["Говорят ты в средний класс выбился. Уважаю."],
			["Богатый теперь, значит? Помнишь откуда начинал?"],
			["Миллионер! Ну ты даёшь. Я б на твоём месте уехал отсюда."],
			["Мультимиллионер из «Зари»... Гордость района, честно слово."],
		]},
		{"name":"👵 Баба Нюра",   "pos":Vector2( 350, 350), "lines":["Опять молодёжь во дворе шляется...", "Сходи в ЖЭК — там работа бывает. Им всегда разнорабочие нужны.", "Аптека здесь хорошая. Только дорого всё."], "title_lines":[
			["Опять молодёжь во дворе шляется...", "Работать надо, а не бездельничать!"],
			["Хоть немного заработал? Ну и слава богу."],
			["Слышала, ты в магазинчик пошёл работать. Не стыдно?", "Шучу, шучу. Труд — не позор."],
			["Ты поднялся, внучок. Мама была бы рада."],
			["Говорят квартиру купил? Молодец. А у нас хоть тихо."],
			["Тебя в газете печатают? Надо же... Из наших!"],
			["Мультимиллионер. Я тебя ещё малым помню во дворе."],
		]},
		{"name":"👮 Участковый",   "pos":Vector2(-600, 200), "lines":["Документы при себе? Всё нормально, проходи.", "Порядок в микрорайоне — моя забота. Иди работай.", "Тут тихо. Стройку только объезжай — там опасно."], "title_lines":[
			["Документы при себе? Всё нормально, проходи."],
			["Слышал, работать начал. Хорошо. Меньше проблем у меня."],
			["Ты теперь приличный человек. Нареканий нет."],
			["Среднего класса достиг — это уже не шутки. Респект."],
			["Богатые тоже платят налоги. Помни об этом."],
			["Говорят, бизнес открыл? Не нарушай — проверю."],
			["Мультимиллионер... Ты теперь выше моего начальника."],
		]},
		{"name":"🧒 Димка",        "pos":Vector2( 600, 500), "lines":["Эй, на стройке платят неплохо если не боишься.", "Я тут живу с рождения. Нормальный район, только скучно.", "Шаурма тут лучшая в округе, без базара."], "title_lines":[
			["Эй, на стройке платят неплохо если не боишься."],
			["Слышь, ты хоть немного поднялся уже?"],
			["Нормально, растёшь! Я всегда говорил — ты пробьёшься."],
			["Средний класс, значит. Берёшь меня в напарники?"],
			["Ты богатый уже? Отвези меня на своей тачке хоть раз!"],
			["Миллионер! Помнишь как мы шаурму делили на двоих?"],
			["Вот это карьера. Хоть расскажи как ты это сделал!"],
		]},
		{"name":"🥃 Алкаш Толик", "pos":Vector2(-550, 600), "lines":["Земляк, дай рублей на бутылку, а? Не последнее же отдаю...", "Сидел тут под подъездом всю жизнь, и дальше буду сидеть.", "Эх, были деньги — пропил всё. Не повторяй моих ошибок."], "title_lines":[]},
		{"name":"🧢 Шустрый Лёха", "pos":Vector2( 800, 650), "lines":["Слушай, бошку не подставляй — здесь по карманам шарят.", "Я сам чист, просто... мимо проходил. Честно-честно.", "Кошелёк держи крепче, особенно вечером у мусорок."], "title_lines":[]},
	],
	[
		{"name":"👷 Бригадир Степаныч", "pos":Vector2(-700, 200), "lines":["На заводе нужны руки — иди в «ГлавПром», там не обидят.", "Стройка — тяжело, зато честно. Не пожалеешь.", "На рынке тоже можно подняться, если умеешь торговать."], "title_lines":[
			["Новенький в квартале? На завод иди — там берут без вопросов."],
			["Слышал, начал подрабатывать. Молодец. Главное — не лениться."],
			["Освоился уже? На «ГлавПроме» так и говорят: сначала тяжело, потом привыкаешь."],
			["Средний класс! Растёшь. Скоро меня перегонишь, наверное."],
			["Богатый человек к нам заглядывает? Помни откуда начинал, брат."],
			["Миллионер! Я всегда говорил — ты пробьёшься. Серьёзный парень был."],
			["Мультимиллионер из рабочего квартала... Это надо же. Горжусь."],
		]},
		{"name":"👩‍🏭 Работница Галя",   "pos":Vector2( 300, 380), "lines":["В цеху жарко, зато зарплата белая. Почти.", "Столовая на заводе нормальная — три раза в день кормят.", "На рынке беру овощи — там дешевле, чем в магазине."], "title_lines":[
			["Ты у нас новый? В цеху №3 набор идёт — зайди к мастеру."],
			["Работаешь потихоньку? Главное не прогуливать — штрафуют."],
			["Смены длинные, но ничего — привыкнешь. Мы все так начинали."],
			["Ты уже в средний класс выбился? Молодец. Я вот ещё тут."],
			["Богатый! Может, возьмёшь нашу смену под своё начало? Шучу, шучу."],
			["Миллионер из нашего цеха! Девчата не поверят, если расскажу."],
			["Мультимиллионер... А я помню тебя на конвейере. Эх, время летит."],
		]},
		{"name":"🚛 Водила Вася",        "pos":Vector2(-250, 430), "lines":["Склад №7 — самое спокойное место в квартале.", "Дальнобой уже не для меня. Теперь по городу — и то хорошо.", "Пивная «Факел» — единственное нормальное заведение тут."], "title_lines":[
			["Склад ищешь? Прямо и направо. Там грузчики всегда нужны."],
			["Видел тебя вчера — вкалываешь. Вот это правильно."],
			["Уже освоился? На складе и зарплата получше бывает, если стараться."],
			["Средний класс! Значит, из нашего квартала не только я уходил наверх."],
			["Богатый! Слушай, подбрось до центра на своей тачке? Шучу."],
			["Миллионер из Рабочего квартала... Уважаю. Без шуток."],
			["Мультимиллионер. Ты теперь в другой лиге, брат. Удачи тебе."],
		]},
		{"name":"🔩 Слесарь Митя",       "pos":Vector2( 600,-500), "lines":["Авторемонт — лучшая работа в квартале. Руки — голова.", "ПТУ закончил — и нормально живу. Не хуже других.", "Медпункт здесь хороший — главврач нормальный мужик."], "title_lines":[
			["ПТУ видел? Советую — профессия на всю жизнь."],
			["Подрабатываешь? Авторемонт платит больше, если руки из плеч."],
			["Слышал, ты на заводе уже? Серьёзная работа. Респект."],
			["Средний класс достиг? Значит, ПТУ не зря — образование везде помогает."],
			["Ого, богатый уже! А я всё ещё гайки кручу. Но мне нравится."],
			["Миллионер! Слушай, может мастерскую мне помоги открыть? Серьёзно."],
			["Мультимиллионер... Я горжусь, что знал тебя. Ты молодец, Митя говорит."],
		]},
		{"name":"🛠 Торговец Семёныч", "pos":Vector2(-450, 500), "lines":["На рынке всё найдёшь — от гвоздя до телевизора.", "Торгую тут уже лет двадцать. Постоянные клиенты знают.", "Бери что нужно, сторгуемся — для своих скидка."], "title_lines":[]},
	],
	[
		{"name":"👩 Продавщица Люда",    "pos":Vector2( 600,-500), "lines":["Берёшь что-нибудь или так стоишь?","У нас всё свежее! Почти...","В Спальном районе неплохо жить. Тихо, зелено."], "title_lines":[
			["Берёшь что-нибудь? У нас свежая выпечка из кафе рядом!"],
			["Слыхала, ты подрабатываешь. Молодец, так и надо."],
			["Бариста работаешь? Я тоже начинала с этого."],
			["В средний класс выбился уже? Хороший район стал мал?"],
			["Богатый человек, а всё равно к нам заходишь. Уважаю!"],
			["Говорят ты миллионер? Может нашу Пиццерию купишь?"],
			["Мультимиллионер... Я твою первую пиццу помню. Дорожал ты быстро."],
		]},
		{"name":"🧑 Алёша (молодой папа)","pos":Vector2(-200, 430), "lines":["Гуляю с ребёнком пока жена работает.","Хороший район для семьи. Школа рядом, парк есть.","В фитнес-центр заглядывай — там и работу можно найти."], "title_lines":[
			["Ты новый в районе? Добро пожаловать. Хорошее место."],
			["Видел тебя в кафе — там неплохо платят за смену."],
			["Подрабатываешь здесь? Правильно, в парке и думается лучше."],
			["Средний класс — это мечта. Для семьи стабильность важна."],
			["Ого, вот это карьера! Уже богатый? Позавидую по-хорошему."],
			["Миллионер из нашего двора... Дочка вырастет — расскажу ей."],
			["Мультимиллионер. Помнишь как мы в парке на скамейке сидели?"],
		]},
		{"name":"👴 Дедушка Иван",       "pos":Vector2( 300, 380), "lines":["Раньше тут поля были. Теперь сплошные дома.","Пенсия маленькая, но в кафе иногда захожу.","Молодёжь бегает в фитнес. Я предпочитаю сквер."], "title_lines":[
			["Раньше тут поля были. Ты тоже новенький в районе?"],
			["На кафе или Пиццерию хожу иногда. Жить можно."],
			["Работаешь бариста? Хорошая работа, уважаемая."],
			["Средний класс достиг? Дай бог тебе здоровья, сынок."],
			["Богатый человек. Помни откуда пришёл — вот мой тебе совет."],
			["Миллионер! Я ещё помню, как ты в этот район приехал."],
			["Мультимиллионер из нашего квартала... Эх, молодость!"],
		]},
		{"name":"🧕 Тётя Зина",          "pos":Vector2(-700, 200), "lines":["Аптека тут хорошая — зайди если что.","В поликлинике очереди небольшие. Повезло нам.","Колледж рядом — учись пока молодой!"], "title_lines":[
			["Аптека тут хорошая — зайди если что. Здоровье дороже денег."],
			["Работаешь? Молодец. В нашем районе ленивых нет."],
			["В кафе помогаешь? Я там пирожки беру — вкусные!"],
			["Средний класс! Хорошо устроился. Квартиру снимаешь?"],
			["Богатый уже? Не забывай колледж — знания важнее денег."],
			["Говорят миллионер. Район тебя вырастил, помни об этом."],
			["Мультимиллионер! Ну и дела... Всё равно в аптеку заходи."],
		]},
		{"name":"🗺 Турист Игорь", "pos":Vector2(-450, 550), "lines":["Привет! Не подскажешь, как до центра дойти? А, неважно, сам разберусь.", "Город у вас интересный, фотографирую тут всё подряд.", "Если что — всегда могу подсказать дорогу, я уже неделю тут хожу."], "title_lines":[]},
	],
	[
		{"name":"🧑‍💻 IT-специалист Антон", "pos":Vector2( 600,-500), "lines":["Всё можно автоматизировать. Даже жизнь.", "Данные — новая нефть. БЦ «Атлас» напротив — там отличные офисы.", "Инвест.банк здесь топ — я уже второй депозит открыл."], "title_lines":[
			[],[],[],[],[],[],
			["Новенький? Средний класс — хорошее место чтобы начать расти."],
			["Средний класс. Добро пожаловать в приличное общество!"],
			["Уже Специалист? Инвест.банк теперь твой — пользуйся."],
			["Менеджер в нашем квартале? Явно метишь выше."],
			["Богатый уже? Вкладывай в инвест.банк — он тут надёжный."],
			[],
			["Миллионер... Я тебя помню у Кофе «Арома» с ноутбуком."],
			[],
			["Мультимиллионер! Может стартап запустим вместе? Серьёзно."],
		]},
		{"name":"👩‍💼 Менеджер Катя",      "pos":Vector2(-200, 430), "lines":["Бизнес-ланч в ресторане — лучшее изобретение.", "Инвест.банк здесь хороший — рассмотри депозит.", "Карьера — это марафон, не спринт. Главное — образование."], "title_lines":[
			[],[],[],[],[],[],
			["Приятно видеть новых людей в квартале. Вы тут надолго?"],
			["Средний класс — это уже серьёзно. Университет закончил?"],
			["Специалист в нашем районе — это звучит. Что дальше планируете?"],
			["Коллега! Зайдём на бизнес-ланч в ресторан?"],
			["Богатый человек в нашем районе? Добро пожаловать, коллега!"],
			[],
			["Миллионер! Значит, инвестиции сработали. Рада за вас."],
			[],
			["Мультимиллионер... Теперь уже я у вас советов спрошу."],
		]},
		{"name":"🔧 Автомеханик Серёга",   "pos":Vector2( 350, 380), "lines":["Открыл тут сервис. Доход неплохой, конкуренция слабая.", "Авторынок тут живой — клиенты приходят каждый день.", "В парке после смены хорошо посидеть — фонтан освежает."], "title_lines":[
			[],[],[],[],[],[],
			["Машина не нужна? Вон авторынок — хорошие тачки есть."],
			["Средний класс! Пора купить нормальную тачку, а не подержанку."],
			["Специалист уже? Можешь теперь хорошую тачку взять в кредит."],
			["Менеджер с колёсами — это сила. Видел тебя в новой машине."],
			["Богатый стал? Значит пора на мышцу пересаживаться!"],
			[],
			["Миллионер! Тебе уже не ко мне — к официальному дилеру."],
			[],
			["Мультимиллионер... Для старого клиента персональная скидка."],
		]},
		{"name":"👩‍🎓 Студентка Маша",       "pos":Vector2(-700,-300), "lines":["Учусь в университете на третьем курсе. Осталось немного!", "Библиотека тут отличная. Можно часами сидеть.", "После пар всегда захожу в Кофе «Арома» — там уютно."], "title_lines":[
			[],[],[],[],[],[],
			["Ты в университет поступать? Советую — меняет жизнь!"],
			["Средний класс! Ты добился того, к чему я стремлюсь. Молодец!"],
			["Специалист! Значит, Бакалавр уже получил? Поздравляю!"],
			["Менеджер... Когда вырасту — тоже стану. Точно."],
			["Богатый человек... Что тебя в наш квартал привело?"],
			[],
			["Миллионер у университета... Лекцию нам не прочитаешь?"],
			[],
			["Мультимиллионер! Вот с кого надо брать пример, а не с учебников."],
		]},
	],
	[
		{"name":"💼 Бизнесмен Петрович", "pos":Vector2( 400,-500), "lines":["Время — деньги. Каждая секунда здесь чего-то стоит.", "Биржа — главное место района. Освоишься — озолотишься.", "Технопарк открыли недавно. Говорят, там стартапы поднимают миллионы."], "title_lines":[
			[],[],[],[],
			["Бедный в Бизнес-квартале? Смелый шаг. Здесь деньги делают деньги."],
			["Работяга с амбициями — уважаю. Биржа рядом, начни с малого."],
			["Простой — хороший старт. Технопарк открыт, стартапы ждут."],
			["Средний класс! Добро пожаловать в мир настоящего бизнеса."],
			["Специалист. Вклад, биржа, стартап — пора запустить всё вместе."],
			["Менеджер в нашем квартале? Ты управляешь, а не подчиняешься."],
			["Богатый! Десять миллионов — серьёзно. Теперь инвестируй крупно."],
			["Предприниматель. Ты создаёшь стоимость. Редкий талант — цени."],
			["Миллионер! Я следил за твоим ростом. Серьёзный результат."],
			[],
			["Мультимиллионер из Бизнес-квартала... Это вершина карьеры здесь."],
		]},
		{"name":"🧑‍💼 Брокер Антон",    "pos":Vector2(-200, 430), "lines":["Сегодня купил — завтра продал. Такая работа.", "Офис-центр напротив — переговорные всегда заняты.", "Мэрия отлично помогает с бизнесом. Очередей почти нет."], "title_lines":[
			[],[],[],[],
			["Новенький с небольшим капиталом? Нормально. Я начинал так же."],
			["Работяга на бирже? Начни с голубых фишек — меньше риска."],
			["Простой — хорошая база. Торговый зал рядом, попробуй форекс."],
			["Средний класс! Портфель диверсифицируй — акции и вклад."],
			["Специалист. ETF и облигации уже доступны — сложные инструменты."],
			["Менеджер. С таким капиталом видна разница между инвестором и спекулянтом."],
			["Богатый — добро пожаловать в клуб. Венчурный фонд — следующий уровень."],
			["Предприниматель. Ты думаешь правильно: деньги должны приносить деньги."],
			["Миллионер! Держу пари, ты уже подумываешь об элитном районе?"],
			[],
			["Мультимиллионер! Брат, ты обогнал меня. Снимаю шляпу."],
		]},
		{"name":"👩‍🔬 Аналитик Виктория", "pos":Vector2( 250, 380), "lines":["Без магистратуры здесь не взлететь высоко — это факт.", "Я 6 лет учила финансы, чтобы работать на бирже. Оно того стоит.", "Технопарк — отличный вариант для тех, кто в IT."], "title_lines":[
			[],[],[],[],
			["Здравствуй. Бедный, но в правильном месте. Финансы — это путь."],
			["Работяга? Здесь без образования не взлетишь — иди в Магистратуру."],
			["Простой — уже хорошо. Магистратура откроет лучшие возможности."],
			["Средний класс достиг? Биржа теперь твой инструмент. Изучай рынок."],
			["Специалист. Аналитика говорит: твой момент инвестировать — сейчас."],
			["Менеджер. С твоим капиталом диверсификация обязательна. Это факт."],
			["Богатый! Рынок ценных бумаг — твой лучший друг на этом уровне."],
			["Предприниматель. Я анализировала твой портфель — выглядит сильно."],
			["Миллионер! Я помню, как ты только пришёл сюда. Гордость берёт."],
			[],
			["Мультимиллионер... Ты сам теперь — кейс для бизнес-школы."],
		]},
		{"name":"👨‍💻 Разработчик Макс",  "pos":Vector2(-350, -300), "lines":["В Технопарке классно работать — открытое пространство, кофе, команда.", "Если хочешь стартап — заходи в Технопарк. Там помогут с идеей.", "Бизнес-кафе рядом — там весь квартал встречается по утрам."], "title_lines":[
			[],[],[],[],
			["Видел тебя у Технопарка? Заходи — всегда нужны свежие мозги."],
			["Работяга? В IT зарабатывают x3 от обычного. Не упусти шанс."],
			["Простой — в Технопарке работают в основном такие же как ты."],
			["Средний класс! Уже можешь вложиться в стартап. Рассматриваешь?"],
			["Специалист. Технопарк, биржа, вклад — запусти всё параллельно."],
			["Менеджер. Венчурный фонд тебе открыт. Стоит попробовать."],
			["Богатый уже? Может, инвестируешь в наш стартап? Серьёзно спрашиваю."],
			["Предприниматель. Я уже вижу тебя в списке наших инвесторов."],
			["Миллионер! Слушай, давай партнёрство — ты деньги, я код."],
			[],
			["Мультимиллионер... Ты обогнал всех нас. Горжусь, что знал тебя."],
		]},
		{"name":"🧑‍💰 Инвестор Борис",   "pos":Vector2(-600,-400), "lines":["Управляю фондом 20 лет. Главное правило — диверсификация.", "Венчурный фонд здесь — один из лучших. Сам вложился в трёх стартаперов.", "Биржа, вклады, стартапы — три кита правильного портфеля."], "title_lines":[
			[],[],[],[],
			["Молодой человек с небольшим капиталом? Правильно начинаете — с малого."],
			["Работяга? В инвестициях главное — регулярность, а не размер вложения."],
			["Простой — хорошая база. Начните с вклада, потом добавьте акции."],
			["Средний класс! Пора строить диверсифицированный портфель. Помогу советом."],
			["Специалист. Ваш капитал уже позволяет смотреть на Венчурный фонд."],
			["Менеджер — серьёзный уровень. Венчурные инвестиции — это ваша история."],
			["Богатый! Мой фонд ищет со-инвесторов. Поговорим серьёзно?"],
			["Предприниматель. У нас похожий путь. Можем стать партнёрами."],
			["Миллионер! Поздравляю. Теперь вы сами можете создать собственный фонд."],
			[],
			["Мультимиллионер... Когда-то я мечтал о таком результате. Достойно."],
		]},
	],
	[
		{"name":"🏖 Олигарх",           "pos":Vector2( 600,-500), "lines":["Деньги — это свобода. Всё остальное — иллюзия.", "Я начинал с нуля. В 90-е. Не спрашивай как.", "Яхт-клуб здесь мой. Заходи как-нибудь."], "title_lines":[]},
		{"name":"👩 Светская дама",      "pos":Vector2(-200, 430), "lines":["Казино открылось — теперь есть куда вечером.", "Аэропорт рядом. Завтра в Монако.", "В частной клинике тут лучшие врачи города."], "title_lines":[]},
		{"name":"🧔 Телохранитель",       "pos":Vector2( 300, 380), "lines":["Работа простая: охраняю босса 24/7.", "Зарплата хорошая. Расходы минимальные.", "Если хочешь в охрану — посмотри объявления в ТЦ."], "title_lines":[]},
	],
	[
		{"name":"🤴 Мультимиллионер",    "pos":Vector2( 600,-500), "lines":["Добро пожаловать в элиту.", "Здесь только сильнейшие. Ты заслужил.", "Дворец строили 3 года. Того стоило."], "title_lines":[]},
		{"name":"🧑‍🎨 Архитектор",        "pos":Vector2(-200, 430), "lines":["Все здания в этом квартале — мои проекты.", "Олигархи знают толк в архитектуре. Платят хорошо.", "Замки строим на совесть. Века простоят."], "title_lines":[]},
		{"name":"👩‍💼 Советник",           "pos":Vector2( 300, 380), "lines":["Я помогаю богатым стать ещё богаче.", "Нефтяная вышка — самый стабильный актив.", "Офшорный счёт — не роскошь, а необходимость."], "title_lines":[]},
	],
	[
		{"name":"🕴 Министр",            "pos":Vector2( 600,-500), "lines":["Здесь решаются судьбы страны.", "Добро пожаловать в коридоры власти.", "Госконтракт — это не просто деньги, это ответственность."], "title_lines":[]},
		{"name":"💂 Охранник КПП",        "pos":Vector2(-200, 430), "lines":["Пропуск есть? Проходите.", "Здесь каждый метр под наблюдением.", "Министерство работает круглосуточно. Такая работа."], "title_lines":[]},
		{"name":"👩‍💼 Чиновница",           "pos":Vector2( 300, 380), "lines":["Посольство? Налево и через два КПП.", "Академия наук — лучшее место для карьеры учёного.", "Госбанк здесь надёжнее любого частного."], "title_lines":[]},
	],
	[
		{"name":"👑 Сенатор",            "pos":Vector2( 600,-500), "lines":["Ты добрался до вершины.", "Немногие достигают этого уровня. Поздравляю.", "Отсюда виден весь город. Буквально и образно."], "title_lines":[]},
		{"name":"🧑‍✈️ Пилот",              "pos":Vector2(-200, 430), "lines":["Вертодром работает с 6 утра. Расписание плотное.", "Ангары за зоной — там частные борта.", "На медиа-сделках зарабатывают больше нефти."], "title_lines":[]},
		{"name":"🤖 ИИ-консультант",      "pos":Vector2( 300, 380), "lines":["Я анализирую рынки быстрее любого человека.", "Госконтракт на 10 миллионов — это только начало.", "Если ты здесь — значит система работает."], "title_lines":[]},
	],
]

# ─── Декоративные здания по зонам ────────────────────────────────────────────
const DECO_ZONES: Array = [
	# Зона 0 — Трущобы. Бараки, хрущёвки, запустение.
	# Центральный сквер с фонтаном, Дом культуры, спортплощадка.
	[
		# ══ СЕВЕРНЫЕ 9-ЭТАЖКИ (y≈-940) — три панельных башни ══
		{"emoji":"🏢","label":"Заря-1\n9эт","w":255,"h":165,"color":Color(0.50,0.52,0.56),"pos":Vector2(-1055,-940)},
		{"emoji":"🏢","label":"Заря-2\n9эт","w":250,"h":165,"color":Color(0.52,0.54,0.58),"pos":Vector2( -660,-940)},
		{"emoji":"🏢","label":"Заря-3\n9эт","w":245,"h":165,"color":Color(0.50,0.53,0.57),"pos":Vector2( -170,-940)},

		# ══ КИРПИЧНЫЙ КВАРТАЛ СЗ (y≈-680) — тёплый контраст серым панелькам ══
		{"emoji":"🏠","label":"д.Б-1\n5эт","w":188,"h":128,"color":Color(0.60,0.40,0.28),"pos":Vector2(-1065,-680)},
		{"emoji":"🏠","label":"д.Б-2\n5эт","w":182,"h":128,"color":Color(0.62,0.38,0.26),"pos":Vector2( -755,-680)},

		# ══ ХРУЩЁВКИ ВДОЛЬ УЛ.РАССВЕТНОЙ (y≈-655) ══
		{"emoji":"🏠","label":"д.3\n5эт","w":175,"h":125,"color":Color(0.65,0.60,0.50),"pos":Vector2(-250,-655)},
		{"emoji":"🏠","label":"д.4\n5эт","w":170,"h":125,"color":Color(0.63,0.58,0.48),"pos":Vector2( 120,-655)},
		{"emoji":"🏠","label":"д.5\n5эт","w":165,"h":125,"color":Color(0.65,0.60,0.50),"pos":Vector2( 530,-655)},

		# ══ СРЕДНИЙ БЛОК (y≈-365) ══
		{"emoji":"🏢","label":"Заря-4\n9эт","w":248,"h":162,"color":Color(0.50,0.52,0.55),"pos":Vector2(-1065,-365)},
		{"emoji":"🏢","label":"Заря-5\n9эт","w":242,"h":162,"color":Color(0.52,0.54,0.57),"pos":Vector2( -585,-365)},
		{"emoji":"🏢","label":"д.6\n9эт",   "w":228,"h":162,"color":Color(0.50,0.56,0.64),"pos":Vector2(  590,-365)},

		# ══ ДОМ КУЛЬТУРЫ (зап. якорь) ══
		{"emoji":"🎭","label":"Дом\nкультуры","w":235,"h":105,"color":Color(0.68,0.62,0.35),"pos":Vector2(-1065, 48)},
		{"emoji":"","label":"","w":12,"h":105,"color":Color(0.82,0.76,0.54),"pos":Vector2(-1065, 48)},
		{"emoji":"","label":"","w":12,"h":105,"color":Color(0.82,0.76,0.54),"pos":Vector2( -940, 48)},
		{"emoji":"","label":"","w":12,"h":105,"color":Color(0.82,0.76,0.54),"pos":Vector2( -848, 48)},

		# ══ ХРУЩЁВКИ ЦЕНТРАЛЬНОГО РЯДА (y≈-72) ══
		{"emoji":"🏠","label":"д.7\n5эт","w":178,"h":126,"color":Color(0.64,0.59,0.49),"pos":Vector2(-1065,-72)},
		{"emoji":"🏠","label":"д.8\n5эт","w":168,"h":126,"color":Color(0.52,0.57,0.65),"pos":Vector2(  430,-72)},
		{"emoji":"🏠","label":"д.9\n5эт","w":162,"h":126,"color":Color(0.50,0.55,0.62),"pos":Vector2(  750,-72)},

		# ══ ЦЕНТРАЛЬНЫЙ СКВЕР «ЗАРЯ» ══
		{"emoji":"🌿","label":"Сквер «Заря»","w":375,"h":260,"color":Color(0.24,0.52,0.24),"pos":Vector2(-105,-340)},
		{"emoji":"","label":"","w":375,"h":11,"color":Color(0.76,0.72,0.65),"pos":Vector2(-105,-220)},
		{"emoji":"","label":"","w":11, "h":260,"color":Color(0.76,0.72,0.65),"pos":Vector2(  83,-340)},
		{"emoji":"⛲","label":"Фонтан «Заря»","w":60,"h":60,"color":Color(0.28,0.56,0.84),"pos":Vector2(  55,-250)},
		{"emoji":"🌸","label":"","w":46,"h":30,"color":Color(0.86,0.28,0.42),"pos":Vector2( -98,-310)},
		{"emoji":"🌸","label":"","w":46,"h":30,"color":Color(0.84,0.56,0.16),"pos":Vector2( 195,-310)},
		{"emoji":"🌸","label":"","w":46,"h":30,"color":Color(0.32,0.72,0.35),"pos":Vector2( -98,-170)},
		{"emoji":"🌸","label":"","w":46,"h":30,"color":Color(0.64,0.22,0.72),"pos":Vector2( 195,-170)},
		{"emoji":"🪑","label":"","w":32,"h":12,"color":Color(0.45,0.28,0.14),"pos":Vector2(  30,-292)},
		{"emoji":"🪑","label":"","w":32,"h":12,"color":Color(0.45,0.28,0.14),"pos":Vector2(  30,-188)},
		{"emoji":"🪑","label":"","w":12,"h":32,"color":Color(0.45,0.28,0.14),"pos":Vector2( -10,-260)},
		{"emoji":"🪑","label":"","w":12,"h":32,"color":Color(0.45,0.28,0.14),"pos":Vector2( 148,-260)},
		{"emoji":"🌳","label":"","w":40,"h":40,"color":Color(0.14,0.46,0.14),"pos":Vector2(-105,-340)},
		{"emoji":"🌳","label":"","w":40,"h":40,"color":Color(0.16,0.48,0.16),"pos":Vector2( 230,-340)},
		{"emoji":"🌳","label":"","w":40,"h":40,"color":Color(0.14,0.46,0.14),"pos":Vector2(-105, -88)},
		{"emoji":"🌳","label":"","w":40,"h":40,"color":Color(0.16,0.48,0.16),"pos":Vector2( 230, -88)},
		{"emoji":"🌲","label":"","w":28,"h":28,"color":Color(0.12,0.40,0.12),"pos":Vector2(  55,-340)},
		{"emoji":"🌲","label":"","w":28,"h":28,"color":Color(0.12,0.40,0.12),"pos":Vector2( 160,-340)},
		{"emoji":"🌲","label":"","w":28,"h":28,"color":Color(0.12,0.40,0.12),"pos":Vector2(  55,-100)},
		{"emoji":"🌲","label":"","w":28,"h":28,"color":Color(0.12,0.40,0.12),"pos":Vector2( 160,-100)},

		# ══ ЮЖНЫЙ ЖИЛОЙ БЛОК ══
		{"emoji":"🏠","label":"д.10\n5эт","w":178,"h":126,"color":Color(0.62,0.57,0.47),"pos":Vector2(-1065, 255)},
		{"emoji":"🏠","label":"д.11\n5эт","w":172,"h":126,"color":Color(0.60,0.55,0.45),"pos":Vector2( -645, 255)},
		{"emoji":"🏠","label":"д.12\n5эт","w":165,"h":126,"color":Color(0.52,0.58,0.65),"pos":Vector2(  560, 255)},
		{"emoji":"🏢","label":"Заря-6\n9эт","w":238,"h":155,"color":Color(0.50,0.50,0.52),"pos":Vector2(-1065, 545)},
		{"emoji":"🏢","label":"Заря-7\n9эт","w":232,"h":155,"color":Color(0.48,0.48,0.50),"pos":Vector2( -545, 545)},

		# ══ КРАЙНИЙ ЮГ ══
		{"emoji":"🏢","label":"Заря-8\n9эт", "w":248,"h":155,"color":Color(0.50,0.52,0.55),"pos":Vector2(-1072, 838)},
		{"emoji":"🏢","label":"Заря-9\n9эт", "w":242,"h":155,"color":Color(0.48,0.50,0.53),"pos":Vector2( -542, 838)},
		{"emoji":"🏢","label":"Заря-10\n9эт","w":225,"h":155,"color":Color(0.50,0.50,0.52),"pos":Vector2(  118, 838)},

		# ══ СПОРТИВНАЯ ПЛОЩАДКА (двор ЮВ) ══
		{"emoji":"🏀","label":"Спорт.\nплощ.","w":132,"h":80,"color":Color(0.55,0.38,0.15),"pos":Vector2( 615, 400)},
		{"emoji":"","label":"","w":132,"h":4, "color":Color(0.84,0.72,0.28),"pos":Vector2( 615, 440)},
		{"emoji":"","label":"","w":4,  "h":80,"color":Color(0.84,0.72,0.28),"pos":Vector2( 679, 400)},
		{"emoji":"","label":"","w":4,  "h":80,"color":Color(0.60,0.48,0.18),"pos":Vector2( 615, 400)},
		{"emoji":"","label":"","w":4,  "h":80,"color":Color(0.60,0.48,0.18),"pos":Vector2( 743, 400)},

		# ══ ГАРАЖНЫЙ КООПЕРАТИВ (ЮВ угол) ══
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.30,0.28,0.26),"pos":Vector2( 700, 530)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.32,0.30,0.28),"pos":Vector2( 763, 530)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.30,0.28,0.26),"pos":Vector2( 826, 530)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.31,0.29,0.27),"pos":Vector2( 889, 530)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.29,0.27,0.25),"pos":Vector2( 952, 530)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.30,0.28,0.26),"pos":Vector2( 700, 583)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.32,0.30,0.28),"pos":Vector2( 763, 583)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.30,0.28,0.26),"pos":Vector2( 826, 583)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.31,0.29,0.27),"pos":Vector2( 889, 583)},

		# ══ ПАРКОВКИ ══
		{"emoji":"🅿","label":"Парковка","w":215,"h":48,"color":Color(0.18,0.18,0.20),"pos":Vector2( 285,-792)},
		{"emoji":"🅿","label":"Парковка","w":195,"h":48,"color":Color(0.18,0.18,0.20),"pos":Vector2(-690, 462)},

		# ══ ДЕТСКИЕ ПЛОЩАДКИ И БЕСЕДКИ ══
		{"emoji":"🛝","label":"Площадка","w":102,"h":74,"color":Color(0.28,0.50,0.28),"pos":Vector2(-368,-558)},
		{"emoji":"🛝","label":"Площадка","w":96, "h":70,"color":Color(0.26,0.48,0.26),"pos":Vector2(-368, 438)},
		{"emoji":"🛝","label":"Площадка","w":88, "h":66,"color":Color(0.28,0.50,0.28),"pos":Vector2( 200, 448)},
		{"emoji":"⛺","label":"Беседка","w":40,"h":40,"color":Color(0.44,0.32,0.18),"pos":Vector2(-232,-538)},
		{"emoji":"⛺","label":"Беседка","w":40,"h":40,"color":Color(0.42,0.30,0.16),"pos":Vector2(-215, 458)},
		{"emoji":"⛺","label":"Беседка","w":40,"h":40,"color":Color(0.44,0.32,0.18),"pos":Vector2( 365, 448)},

		# ══ ДЕРЕВЬЯ вдоль ул.Рассветной (сев. y≈-722) ══
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.44,0.18),"pos":Vector2(-1065,-722)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.22,0.46,0.20),"pos":Vector2( -865,-722)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.44,0.18),"pos":Vector2( -645,-722)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.22,0.46,0.20),"pos":Vector2( -415,-722)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.44,0.18),"pos":Vector2( -155,-722)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.22,0.46,0.20),"pos":Vector2(   85,-722)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.44,0.18),"pos":Vector2(  325,-722)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.22,0.46,0.20),"pos":Vector2(  565,-722)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.44,0.18),"pos":Vector2(  775,-722)},
		# вдоль ул.Рассветной (юж. y≈-585)
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.19,0.42,0.17),"pos":Vector2(-1015,-585)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.21,0.44,0.19),"pos":Vector2( -765,-585)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.19,0.42,0.17),"pos":Vector2( -505,-585)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.21,0.44,0.19),"pos":Vector2( -195,-585)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.19,0.42,0.17),"pos":Vector2(  105,-585)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.21,0.44,0.19),"pos":Vector2(  425,-585)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.19,0.42,0.17),"pos":Vector2(  685,-585)},
		# вдоль ул.Мирной (сев. y≈+38)
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.43,0.18),"pos":Vector2(-1015,  38)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.22,0.45,0.20),"pos":Vector2( -765,  38)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.43,0.18),"pos":Vector2( -385,  38)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.22,0.45,0.20),"pos":Vector2(   50,  38)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.43,0.18),"pos":Vector2(  345,  38)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.22,0.45,0.20),"pos":Vector2(  635,  38)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.43,0.18),"pos":Vector2(  885,  38)},
		# вдоль ул.Мирной (юж. y≈+162)
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2(-1005, 162)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.22,0.45,0.20),"pos":Vector2( -735, 162)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2( -335, 162)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.22,0.45,0.20),"pos":Vector2(   82, 162)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2(  382, 162)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.22,0.45,0.20),"pos":Vector2(  655, 162)},
		# вдоль пр.Северного (зап. x≈-762)
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2(-762,-1065)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.22,0.45,0.20),"pos":Vector2(-762, -805)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2(-762, -505)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.22,0.45,0.20),"pos":Vector2(-762, -205)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2(-762,  148)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.22,0.45,0.20),"pos":Vector2(-762,  448)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2(-762,  748)},
		# вдоль пр.Северного (вост. x≈-682)
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2(-682,-1065)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.22,0.45,0.20),"pos":Vector2(-682, -805)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2(-682, -505)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.22,0.45,0.20),"pos":Vector2(-682, -205)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2(-682,  148)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.22,0.45,0.20),"pos":Vector2(-682,  448)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.43,0.18),"pos":Vector2(-682,  748)},
		# Деревья во дворах
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.15,0.38,0.13),"pos":Vector2(-655,-562)},
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.16,0.40,0.14),"pos":Vector2(-595,-542)},
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.15,0.38,0.13),"pos":Vector2( 125,-552)},
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.16,0.40,0.14),"pos":Vector2( 185,-535)},
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.15,0.38,0.13),"pos":Vector2(-685, 442)},
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.16,0.40,0.14),"pos":Vector2(-625, 462)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.15,0.38,0.13),"pos":Vector2( 202, 452)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.16,0.40,0.14),"pos":Vector2( 252, 478)},

		# ══ ОСТАНОВКИ (декор) ══
		{"emoji":"🚌","label":"ост. Рассветная","w":62,"h":22,"color":Color(0.20,0.35,0.58),"pos":Vector2(-282,-714)},
		{"emoji":"🚌","label":"ост. Мирная",     "w":62,"h":22,"color":Color(0.20,0.35,0.58),"pos":Vector2(-282,  42)},
		{"emoji":"🚌","label":"ост. Северная",   "w":22,"h":62,"color":Color(0.20,0.35,0.58),"pos":Vector2(-728,-315)},

		# ══ МУСОРНЫЕ БАКИ (декор) ══
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2(-882, 808)},
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2(-832, 808)},
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2(-462, 818)},
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2(-412, 818)},
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2( 305, 868)},

		# ══ ЗАБОР СТРОЙКИ СВ (3 стороны, юг открыт) ══
		{"emoji":"🚧","label":"Стройка","w":258,"h":14,"color":Color(0.55,0.42,0.08),"pos":Vector2( 762,-572)},
		{"emoji":"🚧","label":"",        "w":14,"h":215,"color":Color(0.55,0.42,0.08),"pos":Vector2(1006,-572)},
		{"emoji":"🚧","label":"",        "w":14,"h":215,"color":Color(0.55,0.42,0.08),"pos":Vector2( 762,-572)},
		# Декоративный кран
		{"emoji":"","label":"","w":14,"h":165,"color":Color(0.62,0.50,0.18),"pos":Vector2( 970,-572)},
		{"emoji":"","label":"","w":105,"h":12, "color":Color(0.62,0.50,0.18),"pos":Vector2( 872,-570)},
		{"emoji":"","label":"","w":8,  "h":50, "color":Color(0.55,0.44,0.14),"pos":Vector2( 880,-570)},
	],
	# Зона 1 — Рабочий квартал
	# Улицы: ул.Заводская (y≈-500), ул.Рабочая (y≈+200), пр.Советский (x≈-600), ул.Ленина (x≈+400)
	[
		# ══ ЗАВОД «ГЛАВПРОМ» (северо-запад) ══
		{"emoji":"🏭","label":"ГлавПром\nГл. корпус",  "w":310,"h":80, "color":Color(0.32,0.29,0.27),"pos":Vector2(-980,-900), "tex":"res://assets/textures/Factory.png"},
		{"emoji":"🏭","label":"Цех А",                  "w":200,"h":65, "color":Color(0.30,0.28,0.26),"pos":Vector2(-980,-820), "tex":"res://assets/textures/workshop.png"},
		{"emoji":"🏭","label":"Цех Б",                  "w":180,"h":65, "color":Color(0.31,0.29,0.27),"pos":Vector2(-760,-820), "tex":"res://assets/textures/workshop.png"},
		{"emoji":"🏭","label":"Склад сырья",            "w":260,"h":55, "color":Color(0.28,0.26,0.24),"pos":Vector2(-980,-760), "tex":"res://assets/textures/warehouse.png"},
		# Три трубы завода
		{"emoji":"💨","label":"Труба","w":22,"h":140,"color":Color(0.38,0.33,0.28),"pos":Vector2(-820,-950)},
		{"emoji":"💨","label":"Труба","w":18,"h":120,"color":Color(0.38,0.33,0.28),"pos":Vector2(-680,-940)},
		{"emoji":"💨","label":"Труба","w":14,"h":100,"color":Color(0.36,0.31,0.26),"pos":Vector2(-560,-935)},
		# Забор завода
		{"emoji":"🚧","label":"Забор завода","w":320,"h":14,"color":Color(0.42,0.36,0.14),"pos":Vector2(-980,-700)},
		# Бочки у ворот и КПП
		{"emoji":"🛢","label":"Бочки","w":28,"h":20,"color":Color(0.30,0.25,0.15),"pos":Vector2(-658,-780)},
		{"emoji":"🛢","label":"",     "w":28,"h":20,"color":Color(0.32,0.27,0.17),"pos":Vector2(-622,-780)},
		{"emoji":"🏠","label":"КПП",  "w":45,"h":35,"color":Color(0.38,0.35,0.30),"pos":Vector2(-680,-720)},

		# ══ СТРОЙПЛОЩАДКА «МОНОЛИТ» (северо-восток) ══
		# Башенный кран — мачта + горизонтальная стрела
		{"emoji":"🏗","label":"Кран","w":16,"h":260,"color":Color(0.28,0.30,0.35),"pos":Vector2( 820,-920)},
		{"emoji":"",  "label":"",    "w":140,"h":14, "color":Color(0.28,0.30,0.35),"pos":Vector2( 688,-920)},
		{"emoji":"",  "label":"",    "w":50, "h":10, "color":Color(0.28,0.30,0.35),"pos":Vector2( 828,-870)},
		# Строящийся корпус
		{"emoji":"🏢","label":"Корпус\n(стройка)","w":200,"h":130,"color":Color(0.44,0.42,0.40),"pos":Vector2( 680,-800)},
		{"emoji":"🏗","label":"Стройплощадка","w":100,"h":80,"color":Color(0.40,0.36,0.30),"pos":Vector2( 870,-680)},
		# Строй.забор
		{"emoji":"🚧","label":"","w":280,"h":12,"color":Color(0.55,0.44,0.10),"pos":Vector2( 672,-660)},
		{"emoji":"🚧","label":"","w":12,"h":180,"color":Color(0.55,0.44,0.10),"pos":Vector2( 672,-840)},
		{"emoji":"🚧","label":"","w":12,"h":180,"color":Color(0.55,0.44,0.10),"pos":Vector2( 940,-840)},
		# Вагончики и стройматериалы
		{"emoji":"🏠","label":"Вагончик","w":60,"h":32,"color":Color(0.42,0.38,0.22),"pos":Vector2( 840,-645)},
		{"emoji":"🏠","label":"Вагончик","w":55,"h":32,"color":Color(0.40,0.36,0.20),"pos":Vector2( 906,-645)},
		{"emoji":"🧱","label":"Блоки",   "w":40,"h":22,"color":Color(0.55,0.52,0.46),"pos":Vector2( 690,-650)},

		# ══ СКЛАД №7 (центр-север) ══
		{"emoji":"🚛","label":"","w":58,"h":30,"color":Color(0.25,0.30,0.22),"pos":Vector2( 388,-670)},
		{"emoji":"🚛","label":"","w":58,"h":30,"color":Color(0.24,0.28,0.20),"pos":Vector2( 388,-630)},
		{"emoji":"📦","label":"Паллеты","w":30,"h":22,"color":Color(0.44,0.38,0.22),"pos":Vector2( 455,-672)},
		{"emoji":"📦","label":"",       "w":30,"h":22,"color":Color(0.42,0.36,0.20),"pos":Vector2( 455,-644)},

		# ══ ПРОМЗОНА ВОСТОК (склады вдоль ж/д) ══
		{"emoji":"🏭","label":"Склад-А","w":200,"h":65,"color":Color(0.34,0.30,0.26),"pos":Vector2( 680,-900), "tex":"res://assets/textures/warehouse.png"},
		{"emoji":"🏭","label":"Склад-Б","w":185,"h":60,"color":Color(0.32,0.28,0.24),"pos":Vector2( 680,-830), "tex":"res://assets/textures/warehouse.png"},
		{"emoji":"🏭","label":"Склад-В","w":200,"h":65,"color":Color(0.33,0.29,0.25),"pos":Vector2( 680,-760), "tex":"res://assets/textures/warehouse.png"},
		{"emoji":"⛽","label":"Цистерна","w":55,"h":55,"color":Color(0.28,0.26,0.24),"pos":Vector2( 900,-660)},
		{"emoji":"⛽","label":"Цистерна","w":50,"h":50,"color":Color(0.29,0.27,0.25),"pos":Vector2( 965,-660)},

		# ══ ул. ЗАВОДСКАЯ (y≈-500) ══
		{"emoji":"🚌","label":"ост. Заводская","w":58,"h":22,"color":Color(0.22,0.36,0.55),"pos":Vector2(-200,-540)},
		{"emoji":"🚌","label":"ост. Ленина",   "w":58,"h":22,"color":Color(0.22,0.36,0.55),"pos":Vector2( 480,-540)},

		# ══ ОБЩЕЖИТИЯ (жильё рабочих, y≈-450) ══
		{"emoji":"🏢","label":"Общ. №1\n5 эт","w":220,"h":150,"color":Color(0.47,0.44,0.40),"pos":Vector2(-950,-450)},
		{"emoji":"🏢","label":"Общ. №2\n5 эт","w":220,"h":150,"color":Color(0.45,0.42,0.38),"pos":Vector2(-640,-450)},
		{"emoji":"🏢","label":"Общ. №3\n5 эт","w":210,"h":150,"color":Color(0.46,0.43,0.39),"pos":Vector2(-270,-450)},
		{"emoji":"🏢","label":"Общ. №4\n5 эт","w":200,"h":150,"color":Color(0.44,0.41,0.37),"pos":Vector2( 130,-450)},
		{"emoji":"🏢","label":"Общ. №5\n5 эт","w":200,"h":150,"color":Color(0.46,0.43,0.39),"pos":Vector2( 540,-450)},

		# ══ МЕДПУНКТ (запад, y≈+200) ══
		{"emoji":"🏥","label":"Медпункт","w":95,"h":55,"color":Color(0.22,0.52,0.50),"pos":Vector2(-975, 190)},
		{"emoji":"",  "label":"",        "w":10,"h":36,"color":Color(0.85,0.10,0.10),"pos":Vector2(-935, 204)},
		{"emoji":"",  "label":"",        "w":36,"h":10,"color":Color(0.85,0.10,0.10),"pos":Vector2(-952, 213)},
		{"emoji":"🪑","label":"",        "w":32,"h":10,"color":Color(0.44,0.30,0.14),"pos":Vector2(-972, 250)},

		# ══ ЖИЛЫЕ ДОМА (хрущёвки, y≈-180) ══
		{"emoji":"🏠","label":"д.1\n5 эт","w":180,"h":120,"color":Color(0.52,0.48,0.42),"pos":Vector2(-950,-180)},
		{"emoji":"🏠","label":"д.2\n5 эт","w":175,"h":120,"color":Color(0.50,0.46,0.40),"pos":Vector2(-640,-180)},
		{"emoji":"🏠","label":"д.3\n5 эт","w":180,"h":120,"color":Color(0.52,0.48,0.42),"pos":Vector2(-280,-180)},
		{"emoji":"🏠","label":"д.4\n5 эт","w":165,"h":120,"color":Color(0.50,0.46,0.40),"pos":Vector2( 120,-180)},
		{"emoji":"🏠","label":"д.5\n5 эт","w":170,"h":120,"color":Color(0.51,0.47,0.41),"pos":Vector2( 550,-180)},

		# ══ СКВЕР ТРУДОВОЙ СЛАВЫ (центр, y≈+10) ══
		{"emoji":"🌿","label":"Сквер\nТруд. Славы","w":180,"h":120,"color":Color(0.20,0.42,0.18),"pos":Vector2( 180, 10)},
		{"emoji":"🗿","label":"Памятник", "w":30,"h":45,"color":Color(0.50,0.48,0.44),"pos":Vector2( 255, 35)},
		{"emoji":"",  "label":"",         "w":50,"h":12,"color":Color(0.42,0.40,0.36),"pos":Vector2( 245, 80)},
		{"emoji":"🪑","label":"","w":38,"h":12,"color":Color(0.44,0.30,0.14),"pos":Vector2( 200, 90)},
		{"emoji":"🪑","label":"","w":38,"h":12,"color":Color(0.44,0.30,0.14),"pos":Vector2( 300, 90)},
		{"emoji":"🌸","label":"","w":32,"h":22,"color":Color(0.28,0.60,0.22),"pos":Vector2( 195, 14)},
		{"emoji":"🌸","label":"","w":32,"h":22,"color":Color(0.26,0.58,0.20),"pos":Vector2( 315, 14)},
		{"emoji":"🌳","label":"","w":32,"h":32,"color":Color(0.16,0.40,0.14),"pos":Vector2( 180, 10)},
		{"emoji":"🌳","label":"","w":32,"h":32,"color":Color(0.18,0.42,0.16),"pos":Vector2( 328, 10)},

		# ══ АВТОРЕМОНТ (восток, y≈+300) — само здание уже есть как интерактивное ══
		{"emoji":"",  "label":"Навес",     "w":130,"h":40,"color":Color(0.32,0.26,0.16),"pos":Vector2( 840, 345)},
		{"emoji":"",  "label":"",          "w":8,  "h":40,"color":Color(0.40,0.34,0.18),"pos":Vector2( 840, 345)},
		{"emoji":"",  "label":"",          "w":8,  "h":40,"color":Color(0.40,0.34,0.18),"pos":Vector2( 962, 345)},
		{"emoji":"🚗","label":"На ремонте","w":52,"h":28,"color":Color(0.48,0.22,0.18),"pos":Vector2( 848, 348)},
		{"emoji":"🚗","label":"",          "w":52,"h":28,"color":Color(0.22,0.28,0.45),"pos":Vector2( 908, 348)},
		{"emoji":"🛢","label":"","w":20,"h":26,"color":Color(0.18,0.16,0.14),"pos":Vector2( 974, 280)},
		{"emoji":"🛢","label":"","w":20,"h":26,"color":Color(0.20,0.18,0.16),"pos":Vector2( 974, 310)},

		# ══ ЗАПРАВКА АЗС ══
		{"emoji":"⛽","label":"АЗС Лукойл","w":90,"h":55,"color":Color(0.52,0.42,0.16),"pos":Vector2( 680, 250)},
		{"emoji":"",  "label":"",          "w":12,"h":28,"color":Color(0.22,0.35,0.18),"pos":Vector2( 700, 268)},
		{"emoji":"",  "label":"",          "w":12,"h":28,"color":Color(0.22,0.35,0.18),"pos":Vector2( 720, 268)},
		{"emoji":"",  "label":"",          "w":12,"h":28,"color":Color(0.22,0.35,0.18),"pos":Vector2( 740, 268)},

		# ══ ул. РАБОЧАЯ (y≈+200) ══
		{"emoji":"🚌","label":"ост. Рабочая","w":58,"h":22,"color":Color(0.22,0.36,0.55),"pos":Vector2( 100, 160)},

		# ══ ЮЖНЫЙ ЖИЛОЙ КВАРТАЛ (y≈+320) ══
		{"emoji":"🏠","label":"д.6\n5 эт","w":180,"h":120,"color":Color(0.51,0.47,0.41),"pos":Vector2(-950, 320)},
		{"emoji":"🏠","label":"д.7\n5 эт","w":175,"h":120,"color":Color(0.49,0.45,0.39),"pos":Vector2(-640, 320)},
		{"emoji":"🏠","label":"д.8\n5 эт","w":180,"h":120,"color":Color(0.51,0.47,0.41),"pos":Vector2(-280, 320)},
		{"emoji":"🏠","label":"д.9\n5 эт","w":165,"h":120,"color":Color(0.49,0.45,0.39),"pos":Vector2( 120, 320)},
		{"emoji":"🏢","label":"Общ. №6\n9эт","w":220,"h":150,"color":Color(0.47,0.44,0.40),"pos":Vector2( 640, 320)},

		# ══ ПИВНАЯ «ФАКЕЛ» (ЮЗ, y≈+595) ══
		{"emoji":"🍺","label":"Пивная\n«Факел»","w":80,"h":50,"color":Color(0.48,0.26,0.08),"pos":Vector2(-340, 595)},
		{"emoji":"",  "label":"",              "w":80,"h":10,"color":Color(0.62,0.38,0.10),"pos":Vector2(-340, 593)},
		{"emoji":"🪑","label":"","w":24,"h":10,"color":Color(0.42,0.28,0.12),"pos":Vector2(-352, 648)},
		{"emoji":"🪑","label":"","w":24,"h":10,"color":Color(0.42,0.28,0.12),"pos":Vector2(-318, 648)},
		{"emoji":"",  "label":"стол","w":18,"h":18,"color":Color(0.55,0.38,0.18),"pos":Vector2(-342, 630)},
		{"emoji":"🪑","label":"","w":24,"h":10,"color":Color(0.42,0.28,0.12),"pos":Vector2(-296, 648)},
		{"emoji":"🪑","label":"","w":24,"h":10,"color":Color(0.42,0.28,0.12),"pos":Vector2(-262, 648)},
		{"emoji":"",  "label":"стол","w":18,"h":18,"color":Color(0.55,0.38,0.18),"pos":Vector2(-286, 630)},

		# ══ КРАЙНИЙ ЮГ (y≈+600) ══
		{"emoji":"🏠","label":"д.10\n5эт","w":175,"h":120,"color":Color(0.50,0.46,0.40),"pos":Vector2(-950, 600)},
		{"emoji":"🏠","label":"д.11\n5эт","w":170,"h":120,"color":Color(0.52,0.48,0.42),"pos":Vector2(-640, 600)},
		{"emoji":"🏠","label":"д.12\n5эт","w":175,"h":120,"color":Color(0.50,0.46,0.40),"pos":Vector2(-100, 600)},
		{"emoji":"🏠","label":"д.13\n5эт","w":165,"h":120,"color":Color(0.51,0.47,0.41),"pos":Vector2( 150, 600)},

		# ══ ГАРАЖНЫЙ КООПЕРАТИВ (ЮВ угол) ══
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.32,0.30,0.28),"pos":Vector2( 680, 530)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.30,0.28,0.26),"pos":Vector2( 743, 530)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.32,0.30,0.28),"pos":Vector2( 806, 530)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.31,0.29,0.27),"pos":Vector2( 869, 530)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.30,0.28,0.26),"pos":Vector2( 680, 583)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.32,0.30,0.28),"pos":Vector2( 743, 583)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":40,"color":Color(0.30,0.28,0.26),"pos":Vector2( 806, 583)},
		{"emoji":"",  "label":"Ворота КГК","w":60,"h":12,"color":Color(0.40,0.36,0.14),"pos":Vector2( 660, 516)},

		# ══ МУСОРНЫЕ БАКИ ══
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2(-860, 780)},
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2(-810, 780)},
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2( 400, 800)},
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2( 450, 800)},
		{"emoji":"🗑","label":"",    "w":28,"h":20,"color":Color(0.22,0.22,0.22),"pos":Vector2(-430, 460)},
		{"emoji":"🗑","label":"",    "w":28,"h":20,"color":Color(0.22,0.22,0.22),"pos":Vector2(-394, 460)},

		# ══ ДЕРЕВЬЯ вдоль улиц ══
		# ул. Заводская (y≈-570)
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.19,0.41,0.17),"pos":Vector2(-900,-570)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.21,0.43,0.19),"pos":Vector2(-680,-570)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.19,0.41,0.17),"pos":Vector2(-420,-570)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.21,0.43,0.19),"pos":Vector2(-120,-570)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.19,0.41,0.17),"pos":Vector2( 480,-570)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.21,0.43,0.19),"pos":Vector2( 730,-570)},
		# ул. Рабочая (y≈+140)
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.18,0.40,0.16),"pos":Vector2(-900, 140)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.42,0.18),"pos":Vector2(-650, 140)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.18,0.40,0.16),"pos":Vector2(-380, 140)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.42,0.18),"pos":Vector2( -80, 140)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.18,0.40,0.16),"pos":Vector2( 250, 140)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.42,0.18),"pos":Vector2( 520, 140)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.18,0.40,0.16),"pos":Vector2( 750, 140)},
		# пр. Советский (x≈-670)
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.19,0.41,0.17),"pos":Vector2(-670,-900)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.21,0.43,0.19),"pos":Vector2(-670,-650)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.19,0.41,0.17),"pos":Vector2(-670,-380)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.21,0.43,0.19),"pos":Vector2(-670, -80)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.19,0.41,0.17),"pos":Vector2(-670, 280)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.21,0.43,0.19),"pos":Vector2(-670, 600)},
		# Дворовые деревья
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.15,0.36,0.13),"pos":Vector2(-820,-330)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.16,0.38,0.14),"pos":Vector2(-770,-320)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.15,0.36,0.13),"pos":Vector2( 280,-330)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.16,0.38,0.14),"pos":Vector2( 330,-310)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.15,0.36,0.13),"pos":Vector2(-820, 480)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.16,0.38,0.14),"pos":Vector2(-760, 500)},
		# Деревья сквера
		{"emoji":"🌲","label":"","w":20,"h":20,"color":Color(0.14,0.35,0.12),"pos":Vector2( 186, 10)},
		{"emoji":"🌲","label":"","w":20,"h":20,"color":Color(0.16,0.37,0.14),"pos":Vector2( 348, 10)},

		# ══ ЖЕЛЕЗНОДОРОЖНЫЕ ПУТИ (вдоль вост. края) ══
		{"emoji":"🚃","label":"ж/д пути","w":18,"h":900,"color":Color(0.30,0.28,0.25),"pos":Vector2( 980,-950)},
		{"emoji":"",  "label":"","w":28,"h":6,"color":Color(0.26,0.24,0.20),"pos":Vector2( 975,-850)},
		{"emoji":"",  "label":"","w":28,"h":6,"color":Color(0.26,0.24,0.20),"pos":Vector2( 975,-700)},
		{"emoji":"",  "label":"","w":28,"h":6,"color":Color(0.26,0.24,0.20),"pos":Vector2( 975,-550)},
		{"emoji":"",  "label":"","w":28,"h":6,"color":Color(0.26,0.24,0.20),"pos":Vector2( 975,-400)},
		{"emoji":"",  "label":"","w":28,"h":6,"color":Color(0.26,0.24,0.20),"pos":Vector2( 975,-250)},
		{"emoji":"",  "label":"","w":28,"h":6,"color":Color(0.26,0.24,0.20),"pos":Vector2( 975,-100)},

		# ══ ДОСКИ ОБЪЯВЛЕНИЙ ══
		{"emoji":"📋","label":"Вакансии","w":32,"h":28,"color":Color(0.38,0.30,0.18),"pos":Vector2(-200, 170)},
		{"emoji":"📋","label":"Стенд",   "w":32,"h":28,"color":Color(0.36,0.28,0.16),"pos":Vector2( 450,-115)},
		{"emoji":"📋","label":"Профком", "w":32,"h":28,"color":Color(0.34,0.26,0.14),"pos":Vector2(-545, 170)},
	],
	# Зона 2 — Спальный район «Северный» (высотки, бульвары, парк, школы)
	# Улицы (в _spawn_zone2_streets): бул. Молодёжный (y≈-620), ул. Парковая (y≈+130)
	#   пр. Северный (x≈-720), ул. Школьная (x≈+320)
	# Интерактивные: Кафе(-800,-300) Пиццерия(-200,-350) Супермаркет(700,350)
	#   Поликлиника(-900,400) Аптека(800,400) Фитнес(600,-600) Банк(-500,-600)
	#   Колледж(-700,600) Кинотеатр(500,600) Тур.агентство(0,250)
	[
		# ══ СЕВЕРНЫЙ ЖИЛОЙ МАССИВ — 14-16-этажные башни (y≈-870) ══
		{"emoji":"🏢","label":"Башня 1\n16эт","w":128,"h":185,"color":Color(0.50,0.56,0.62),"pos":Vector2(-900,-870)},
		{"emoji":"🏢","label":"Башня 2\n16эт","w":122,"h":178,"color":Color(0.48,0.54,0.60),"pos":Vector2(-678,-870)},
		{"emoji":"🏢","label":"Башня 3\n14эт","w":116,"h":165,"color":Color(0.52,0.57,0.63),"pos":Vector2(-448,-870)},
		{"emoji":"🏢","label":"Башня 4\n16эт","w":128,"h":185,"color":Color(0.50,0.56,0.62),"pos":Vector2(-210,-870)},
		{"emoji":"🏢","label":"Башня 5\n14эт","w":114,"h":162,"color":Color(0.48,0.54,0.60),"pos":Vector2(  30,-870)},
		{"emoji":"🏢","label":"Башня 6\n16эт","w":124,"h":185,"color":Color(0.52,0.58,0.64),"pos":Vector2( 252,-870)},
		{"emoji":"🏢","label":"Башня 7\n14эт","w":114,"h":162,"color":Color(0.50,0.55,0.61),"pos":Vector2( 474,-870)},
		{"emoji":"🏢","label":"Башня 8\n12эт","w":110,"h":145,"color":Color(0.48,0.53,0.59),"pos":Vector2( 700,-870)},
		# ══ ВТОРОЙ РЯД — 10-12-этажные дома (y≈-685) ══
		{"emoji":"🏠","label":"д.9\n10эт", "w":155,"h":135,"color":Color(0.54,0.57,0.61),"pos":Vector2(-900,-685)},
		{"emoji":"🏠","label":"д.10\n10эт","w":150,"h":130,"color":Color(0.52,0.55,0.59),"pos":Vector2(-555,-685)},
		{"emoji":"🏠","label":"д.11\n12эт","w":155,"h":145,"color":Color(0.56,0.59,0.63),"pos":Vector2(-205,-685)},
		{"emoji":"🏠","label":"д.12\n10эт","w":145,"h":128,"color":Color(0.52,0.55,0.59),"pos":Vector2( 135,-685)},
		{"emoji":"🏠","label":"д.13\n12эт","w":155,"h":145,"color":Color(0.54,0.58,0.62),"pos":Vector2( 475,-685)},
		{"emoji":"🏠","label":"д.14\n10эт","w":145,"h":128,"color":Color(0.50,0.54,0.58),"pos":Vector2( 800,-685)},
		# ══ ПАРКОВКИ У БУЛЬВАРА ══
		{"emoji":"🅿","label":"Парковка","w":175,"h":45,"color":Color(0.18,0.18,0.20),"pos":Vector2(-900,-667)},
		{"emoji":"🅿","label":"Парковка","w":150,"h":45,"color":Color(0.18,0.18,0.20),"pos":Vector2( 700,-667)},
		# ══ КВАРТАЛ СРЕДНЕГО ЯРУСА — 8-этажки (y≈-480) ══
		{"emoji":"🏘","label":"д.15\n8эт","w":138,"h":112,"color":Color(0.58,0.56,0.50),"pos":Vector2(-900,-480)},
		{"emoji":"🏘","label":"д.16\n8эт","w":135,"h":108,"color":Color(0.56,0.54,0.48),"pos":Vector2(-150,-480)},
		{"emoji":"🏘","label":"д.17\n8эт","w":138,"h":115,"color":Color(0.58,0.55,0.50),"pos":Vector2( 750,-480)},
		# ══ ДЕТСКИЕ ПЛОЩАДКИ ВО ДВОРАХ ══
		{"emoji":"🛝","label":"Площадка 1","w":95,"h":72,"color":Color(0.28,0.50,0.28),"pos":Vector2(-700,-530)},
		{"emoji":"🛝","label":"Площадка 2","w":90,"h":68,"color":Color(0.26,0.48,0.26),"pos":Vector2( 200,-505)},
		{"emoji":"🛝","label":"Площадка 3","w":88,"h":65,"color":Color(0.28,0.50,0.28),"pos":Vector2(-380, 340)},
		{"emoji":"⛺","label":"Беседка",   "w":38,"h":38,"color":Color(0.40,0.30,0.18),"pos":Vector2(-580,-515)},
		{"emoji":"⛺","label":"Беседка",   "w":38,"h":38,"color":Color(0.38,0.28,0.16),"pos":Vector2( 345,-490)},
		{"emoji":"⛺","label":"Беседка",   "w":38,"h":38,"color":Color(0.40,0.30,0.18),"pos":Vector2(-280, 360)},
		# ══ ТОРГОВАЯ УЛИЦА (y≈-200) ══
		{"emoji":"🏪","label":"Магазин «1»","w":95,"h":68,"color":Color(0.42,0.52,0.44),"pos":Vector2(  50,-200)},
		{"emoji":"🏪","label":"Магазин «2»","w":90,"h":65,"color":Color(0.44,0.50,0.42),"pos":Vector2( 190,-200)},
		{"emoji":"🏪","label":"Цветочный", "w":75,"h":60,"color":Color(0.45,0.38,0.50),"pos":Vector2( 320,-200)},
		{"emoji":"🏪","label":"Химчистка", "w":80,"h":62,"color":Color(0.40,0.44,0.52),"pos":Vector2( 450,-200)},
		{"emoji":"📮","label":"Почта",     "w":80,"h":65,"color":Color(0.55,0.22,0.22),"pos":Vector2(-550,-200)},
		{"emoji":"💈","label":"Парикмахер","w":75,"h":60,"color":Color(0.30,0.48,0.55),"pos":Vector2( 600,-200)},
		# ══ СПОРТИВНЫЙ КОРТ (y≈+200) ══
		{"emoji":"🏟","label":"Корт",         "w":120,"h":80,"color":Color(0.25,0.35,0.55),"pos":Vector2( 200, 200)},
		# ══ ТЦ «СЕВЕРНЫЙ» (СВ блок) ══
		{"emoji":"🏬","label":"ТЦ «Северный»","w":160,"h":115,"color":Color(0.40,0.50,0.60),"pos":Vector2( 800,  50)},
		{"emoji":"🏪","label":"Магазин",      "w": 90,"h": 68,"color":Color(0.38,0.48,0.56),"pos":Vector2( 800, 200)},
		# ══ ЦЕНТРАЛЬНЫЙ ПАРК «МОЛОДЁЖНЫЙ» (y≈+400..+620) ══
		{"emoji":"⛲","label":"Фонтан",  "w":78,"h":78,"color":Color(0.16,0.40,0.72),"pos":Vector2(-100, 430)},
		{"emoji":"🌳","label":"Парк",   "w":68,"h":68,"color":Color(0.16,0.50,0.18),"pos":Vector2(-400, 430)},
		{"emoji":"🌳","label":"",       "w":62,"h":62,"color":Color(0.18,0.52,0.20),"pos":Vector2(-280, 462)},
		{"emoji":"🌳","label":"",       "w":65,"h":65,"color":Color(0.17,0.51,0.19),"pos":Vector2(-160, 492)},
		{"emoji":"🌳","label":"",       "w":60,"h":60,"color":Color(0.16,0.50,0.18),"pos":Vector2(  50, 462)},
		{"emoji":"🌳","label":"",       "w":65,"h":65,"color":Color(0.18,0.52,0.20),"pos":Vector2( 185, 432)},
		{"emoji":"🌳","label":"",       "w":62,"h":62,"color":Color(0.17,0.51,0.19),"pos":Vector2(-415, 512)},
		{"emoji":"🌳","label":"",       "w":58,"h":58,"color":Color(0.16,0.50,0.18),"pos":Vector2(-262, 542)},
		{"emoji":"🌳","label":"",       "w":62,"h":62,"color":Color(0.18,0.52,0.20),"pos":Vector2(  80, 532)},
		{"emoji":"🌳","label":"",       "w":58,"h":58,"color":Color(0.17,0.51,0.19),"pos":Vector2( 222, 512)},
		{"emoji":"🌳","label":"",       "w":65,"h":65,"color":Color(0.16,0.50,0.18),"pos":Vector2(-380, 592)},
		{"emoji":"🌳","label":"",       "w":60,"h":60,"color":Color(0.18,0.52,0.20),"pos":Vector2(-185, 572)},
		{"emoji":"🌳","label":"",       "w":62,"h":62,"color":Color(0.17,0.51,0.19),"pos":Vector2(  20, 600)},
		{"emoji":"🌳","label":"",       "w":58,"h":58,"color":Color(0.16,0.50,0.18),"pos":Vector2( 162, 582)},
		{"emoji":"🛝","label":"Площадка","w":92,"h":70,"color":Color(0.28,0.52,0.28),"pos":Vector2(-100, 522)},
		{"emoji":"🪑","label":"Скамья", "w":32,"h":18,"color":Color(0.42,0.32,0.18),"pos":Vector2(-340, 402)},
		{"emoji":"🪑","label":"Скамья", "w":32,"h":18,"color":Color(0.40,0.30,0.16),"pos":Vector2(  90, 402)},
		{"emoji":"🪑","label":"Скамья", "w":32,"h":18,"color":Color(0.42,0.32,0.18),"pos":Vector2(-200, 622)},
		# ══ ЮЖНЫЙ КВАРТАЛ (y≈+820) ══
		{"emoji":"⛪","label":"Церковь Всех\nСвятых","w":85,"h":115,"color":Color(0.82,0.80,0.74),"pos":Vector2(-900, 820)},
		{"emoji":"🏫","label":"Школа №12","w":170,"h":118,"color":Color(0.40,0.46,0.58),"pos":Vector2( 100, 830)},
		{"emoji":"🏘","label":"Таунхаус А","w":105,"h":90,"color":Color(0.60,0.55,0.45),"pos":Vector2(-640, 820)},
		{"emoji":"🏘","label":"Таунхаус Б","w":100,"h":88,"color":Color(0.58,0.53,0.43),"pos":Vector2(-440, 820)},
		{"emoji":"🏘","label":"Таунхаус В","w":105,"h":90,"color":Color(0.60,0.55,0.45),"pos":Vector2(-215, 820)},
		# ══ ГАРАЖНЫЙ КООПЕРАТИВ (СВ, y≈+700) ══
		{"emoji":"🚗","label":"Гараж","w":52,"h":42,"color":Color(0.32,0.30,0.28),"pos":Vector2( 700, 700)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":42,"color":Color(0.30,0.28,0.26),"pos":Vector2( 763, 700)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":42,"color":Color(0.32,0.30,0.28),"pos":Vector2( 826, 700)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":42,"color":Color(0.31,0.29,0.27),"pos":Vector2( 889, 700)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":42,"color":Color(0.30,0.28,0.26),"pos":Vector2( 700, 753)},
		{"emoji":"🚗","label":"Гараж","w":52,"h":42,"color":Color(0.32,0.30,0.28),"pos":Vector2( 763, 753)},
		# ══ ЗАПРАВКА (ЮВ) ══
		{"emoji":"⛽","label":"АЗС «Роснефть»","w":90,"h":58,"color":Color(0.52,0.42,0.18),"pos":Vector2( 880, 820)},
		# ══ МУСОРНЫЕ БАКИ ══
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2(-860, 780)},
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2(-810, 780)},
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2( 380, 800)},
		{"emoji":"🗑","label":"Баки","w":36,"h":26,"color":Color(0.20,0.20,0.20),"pos":Vector2( 430, 800)},
		# ══ ДЕРЕВЬЯ вдоль бул. МОЛОДЁЖНЫЙ (y≈-660 и -580) ══
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.50,0.20),"pos":Vector2(-900,-660)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.22,0.52,0.22),"pos":Vector2(-650,-660)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.50,0.20),"pos":Vector2(-350,-660)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.22,0.52,0.22),"pos":Vector2( -50,-660)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.50,0.20),"pos":Vector2( 250,-660)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.22,0.52,0.22),"pos":Vector2( 550,-660)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.50,0.20),"pos":Vector2( 830,-660)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.48,0.18),"pos":Vector2(-900,-580)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.50,0.20),"pos":Vector2(-620,-580)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.48,0.18),"pos":Vector2(-300,-580)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.50,0.20),"pos":Vector2(  30,-580)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.48,0.18),"pos":Vector2( 380,-580)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.50,0.20),"pos":Vector2( 710,-580)},
		# ══ ДЕРЕВЬЯ вдоль ул. ПАРКОВАЯ (y≈+85 и +175) ══
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.50,0.20),"pos":Vector2(-900,  85)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.22,0.52,0.22),"pos":Vector2(-630,  85)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.50,0.20),"pos":Vector2(-350,  85)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.22,0.52,0.22),"pos":Vector2(  50,  85)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.50,0.20),"pos":Vector2( 380,  85)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.22,0.52,0.22),"pos":Vector2( 680,  85)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.50,0.20),"pos":Vector2( 900,  85)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.18,0.48,0.18),"pos":Vector2(-900, 175)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.50,0.20),"pos":Vector2(-580, 175)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.18,0.48,0.18),"pos":Vector2(-250, 175)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.50,0.20),"pos":Vector2(  80, 175)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.18,0.48,0.18),"pos":Vector2( 430, 175)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.50,0.20),"pos":Vector2( 730, 175)},
		# ══ ДЕРЕВЬЯ вдоль пр. СЕВЕРНЫЙ (x≈-760 и -680) ══
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.50,0.20),"pos":Vector2(-760,-900)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.22,0.52,0.22),"pos":Vector2(-760,-650)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.50,0.20),"pos":Vector2(-760,-380)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.22,0.52,0.22),"pos":Vector2(-760, -80)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.50,0.20),"pos":Vector2(-760, 270)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.22,0.52,0.22),"pos":Vector2(-760, 600)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.18,0.48,0.18),"pos":Vector2(-680,-900)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.50,0.20),"pos":Vector2(-680,-650)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.18,0.48,0.18),"pos":Vector2(-680,-380)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.50,0.20),"pos":Vector2(-680, -80)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.18,0.48,0.18),"pos":Vector2(-680, 270)},
		{"emoji":"🌳","label":"","w":26,"h":26,"color":Color(0.20,0.50,0.20),"pos":Vector2(-680, 600)},
		# ══ ДЕРЕВЬЯ вдоль ул. ШКОЛЬНАЯ (x≈+285 и +370) ══
		{"emoji":"🌲","label":"","w":26,"h":26,"color":Color(0.16,0.44,0.18),"pos":Vector2( 285,-900)},
		{"emoji":"🌲","label":"","w":26,"h":26,"color":Color(0.18,0.46,0.20),"pos":Vector2( 285,-640)},
		{"emoji":"🌲","label":"","w":26,"h":26,"color":Color(0.16,0.44,0.18),"pos":Vector2( 285,-380)},
		{"emoji":"🌲","label":"","w":26,"h":26,"color":Color(0.18,0.46,0.20),"pos":Vector2( 285, -50)},
		{"emoji":"🌲","label":"","w":26,"h":26,"color":Color(0.16,0.44,0.18),"pos":Vector2( 285, 300)},
		{"emoji":"🌲","label":"","w":26,"h":26,"color":Color(0.18,0.46,0.20),"pos":Vector2( 285, 680)},
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.15,0.42,0.17),"pos":Vector2( 370,-900)},
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.17,0.44,0.19),"pos":Vector2( 370,-640)},
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.15,0.42,0.17),"pos":Vector2( 370,-380)},
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.17,0.44,0.19),"pos":Vector2( 370, -50)},
		{"emoji":"🌲","label":"","w":24,"h":24,"color":Color(0.15,0.42,0.17),"pos":Vector2( 370, 300)},
		# ══ ДЕРЕВЬЯ ВО ДВОРАХ ══
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.15,0.40,0.15),"pos":Vector2(-820,-540)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.17,0.42,0.17),"pos":Vector2(-760,-520)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.15,0.40,0.15),"pos":Vector2( 100,-540)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.17,0.42,0.17),"pos":Vector2( 180,-520)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.15,0.40,0.15),"pos":Vector2(-820,-265)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.17,0.42,0.17),"pos":Vector2(-755,-248)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.15,0.40,0.15),"pos":Vector2( 800,-265)},
		{"emoji":"🌲","label":"","w":22,"h":22,"color":Color(0.17,0.42,0.17),"pos":Vector2( 860,-248)},
		# ══ АВТОБУСНЫЕ ОСТАНОВКИ ══
		{"emoji":"🚌","label":"ост. Молодёжный", "w":64,"h":22,"color":Color(0.22,0.38,0.58),"pos":Vector2(   0,-670)},
		{"emoji":"🚌","label":"ост. Парковая",   "w":58,"h":22,"color":Color(0.22,0.38,0.58),"pos":Vector2(   0, 140)},
		{"emoji":"🚌","label":"ост. Южная",      "w":58,"h":22,"color":Color(0.22,0.38,0.58),"pos":Vector2(   0, 760)},
		{"emoji":"🚌","label":"ост. пр.Северный","w":22,"h":64,"color":Color(0.22,0.38,0.58),"pos":Vector2(-730,-290)},
		{"emoji":"🚌","label":"ост. ул.Школьная","w":22,"h":64,"color":Color(0.22,0.38,0.58),"pos":Vector2( 342, -80)},
		# ══ ДОСКИ ОБЪЯВЛЕНИЙ ══
		{"emoji":"📋","label":"Доска","w":32,"h":28,"color":Color(0.38,0.30,0.18),"pos":Vector2(-200, 148)},
		{"emoji":"📋","label":"Доска","w":32,"h":28,"color":Color(0.36,0.28,0.16),"pos":Vector2( 422,-398)},
	],
	# Зона 3 — Средний класс (современный городской район: бизнес-центры, жильё, университет, парк)
	# Интерактивные: Инвест.банк(-800,-300) Автосервис(800,400) Фитнес(-600,500)
	#                Ресторан(700,-500) Налоговая(500,-600) Университет(-900,500) Тур.фирма(0,250)
	[
		# ══ СЕВЕР: ДЕЛОВОЙ БУЛЬВАР — бизнес-центры (y≈-780 до -960) ══
		{"emoji":"🏢","label":"БЦ «Триумф»\n18эт",   "w":145,"h":185,"color":Color(0.30,0.42,0.60),"pos":Vector2(-960,-840)},
		{"emoji":"🏢","label":"БЦ «Меркурий»\n15эт", "w":135,"h":168,"color":Color(0.28,0.40,0.58),"pos":Vector2(-720,-830)},
		{"emoji":"🏢","label":"БЦ «Атлас»\n16эт",    "w":138,"h":172,"color":Color(0.32,0.44,0.62),"pos":Vector2(-440,-840)},
		{"emoji":"🏢","label":"БЦ «Новатор»\n14эт",  "w":128,"h":158,"color":Color(0.26,0.38,0.56),"pos":Vector2(-160,-828)},
		{"emoji":"🏢","label":"БЦ «Прогресс»\n18эт", "w":145,"h":185,"color":Color(0.30,0.42,0.60),"pos":Vector2( 110,-840)},
		{"emoji":"🏢","label":"Офис-центр\n«Восток»","w":155,"h":130,"color":Color(0.34,0.46,0.62),"pos":Vector2( 420,-800)},

		# ══ СЗ: ЖИЛОЙ КВАРТАЛ «ПАРКОВЫЙ» — современные дома (x≈-1050 до -500, y≈-630 до -140) ══
		{"emoji":"🏘","label":"ЖК «Парковый»\nд.1  14эт","w":132,"h":155,"color":Color(0.50,0.55,0.63),"pos":Vector2(-1000,-620)},
		{"emoji":"🏘","label":"д.2  12эт",               "w":122,"h":142,"color":Color(0.48,0.53,0.61),"pos":Vector2( -780,-615)},
		{"emoji":"🏘","label":"д.3  14эт",               "w":128,"h":150,"color":Color(0.52,0.57,0.65),"pos":Vector2( -560,-622)},
		{"emoji":"🏘","label":"д.4  10эт",               "w":118,"h":128,"color":Color(0.47,0.52,0.60),"pos":Vector2(-1000,-400)},
		{"emoji":"🏘","label":"д.5  12эт",               "w":122,"h":142,"color":Color(0.49,0.54,0.62),"pos":Vector2( -775,-397)},
		{"emoji":"🏘","label":"д.6  10эт",               "w":115,"h":128,"color":Color(0.51,0.56,0.64),"pos":Vector2( -550,-402)},
		{"emoji":"🏘","label":"д.7  9эт",                "w":112,"h":118,"color":Color(0.48,0.53,0.61),"pos":Vector2(-1000,-180)},
		{"emoji":"🏘","label":"д.8  9эт",                "w":110,"h":115,"color":Color(0.50,0.55,0.63),"pos":Vector2( -780,-178)},

		# ══ СВ: ОФИСНЫЙ КОМПЛЕКС (x≈+600 до +980, y≈-700 до -160) ══
		{"emoji":"🏢","label":"Правовой\nцентр",  "w":138,"h":118,"color":Color(0.32,0.44,0.60),"pos":Vector2( 950,-680)},
		{"emoji":"🏢","label":"Коворкинг\n«Идея»","w":125,"h":108,"color":Color(0.36,0.48,0.64),"pos":Vector2( 950,-450)},
		{"emoji":"🏢","label":"Бизнес-зал",       "w":115,"h": 98,"color":Color(0.30,0.42,0.58),"pos":Vector2( 950,-230)},

		# ══ ЦЕНТРАЛЬНЫЙ ПРОСПЕКТ (y≈-210 до -90): кофейни, аптека, книжный ══
		{"emoji":"☕","label":"Кофе «Арома»","w":88,"h":68,"color":Color(0.56,0.40,0.22),"pos":Vector2(-560,-178)},
		{"emoji":"💊","label":"Аптека",      "w":90,"h":68,"color":Color(0.20,0.55,0.38),"pos":Vector2(-380,-178)},
		{"emoji":"🌸","label":"Цветы",       "w":72,"h":62,"color":Color(0.62,0.32,0.52),"pos":Vector2(-175,-178)},
		{"emoji":"📚","label":"Книжный",     "w":98,"h":68,"color":Color(0.44,0.38,0.56),"pos":Vector2(  70,-178)},
		{"emoji":"🏪","label":"Магазин",     "w":95,"h":68,"color":Color(0.36,0.50,0.44),"pos":Vector2( 280,-178)},
		{"emoji":"📰","label":"Киоск",       "w":52,"h":48,"color":Color(0.48,0.40,0.28),"pos":Vector2( 460,-178)},
		{"emoji":"🏧","label":"Банкомат",    "w":32,"h":44,"color":Color(0.22,0.35,0.58),"pos":Vector2(-700,-355)},

		# ══ ЦЕНТРАЛЬНЫЙ ПАРК (y≈+340 до +580) ══
		{"emoji":"⛲","label":"Фонтан",   "w":78,"h":78,"color":Color(0.18,0.44,0.74),"pos":Vector2( -90, 425)},
		{"emoji":"🌳","label":"",         "w":58,"h":58,"color":Color(0.16,0.52,0.18),"pos":Vector2(-380, 355)},
		{"emoji":"🌳","label":"",         "w":55,"h":55,"color":Color(0.18,0.54,0.20),"pos":Vector2(-265, 355)},
		{"emoji":"🌳","label":"",         "w":58,"h":58,"color":Color(0.16,0.52,0.18),"pos":Vector2(-150, 355)},
		{"emoji":"🌳","label":"",         "w":55,"h":55,"color":Color(0.18,0.54,0.20),"pos":Vector2( -35, 355)},
		{"emoji":"🌳","label":"",         "w":58,"h":58,"color":Color(0.16,0.52,0.18),"pos":Vector2(  80, 355)},
		{"emoji":"🌳","label":"",         "w":55,"h":55,"color":Color(0.18,0.54,0.20),"pos":Vector2( 185, 360)},
		{"emoji":"🌳","label":"",         "w":52,"h":52,"color":Color(0.16,0.50,0.16),"pos":Vector2(-380, 460)},
		{"emoji":"🌳","label":"",         "w":52,"h":52,"color":Color(0.18,0.52,0.18),"pos":Vector2(-270, 480)},
		{"emoji":"🌳","label":"",         "w":52,"h":52,"color":Color(0.16,0.50,0.16),"pos":Vector2(  55, 490)},
		{"emoji":"🌳","label":"",         "w":52,"h":52,"color":Color(0.18,0.52,0.18),"pos":Vector2( 165, 478)},
		{"emoji":"🌳","label":"",         "w":50,"h":50,"color":Color(0.16,0.50,0.16),"pos":Vector2(-380, 555)},
		{"emoji":"🌳","label":"",         "w":50,"h":50,"color":Color(0.18,0.52,0.18),"pos":Vector2(-265, 570)},
		{"emoji":"🌳","label":"",         "w":50,"h":50,"color":Color(0.16,0.50,0.16),"pos":Vector2(  80, 570)},
		{"emoji":"🌳","label":"",         "w":50,"h":50,"color":Color(0.18,0.52,0.18),"pos":Vector2( 185, 558)},
		{"emoji":"⛺","label":"Павильон", "w":44,"h":44,"color":Color(0.46,0.32,0.18),"pos":Vector2(-195, 488)},
		{"emoji":"⛺","label":"Павильон", "w":40,"h":40,"color":Color(0.44,0.30,0.16),"pos":Vector2(  25, 472)},
		{"emoji":"🛝","label":"Площадка", "w":98,"h":72,"color":Color(0.24,0.48,0.22),"pos":Vector2(-155, 565)},
		{"emoji":"🪑","label":"Скамья","w":40,"h":14,"color":Color(0.38,0.30,0.20),"pos":Vector2(-310, 408)},
		{"emoji":"🪑","label":"Скамья","w":40,"h":14,"color":Color(0.38,0.30,0.20),"pos":Vector2(  78, 408)},
		{"emoji":"🪑","label":"Скамья","w":40,"h":14,"color":Color(0.36,0.28,0.18),"pos":Vector2(-310, 528)},
		{"emoji":"🪑","label":"Скамья","w":40,"h":14,"color":Color(0.36,0.28,0.18),"pos":Vector2(  78, 528)},
		{"emoji":"🌺","label":"Цветник","w":64,"h":22,"color":Color(0.72,0.26,0.42),"pos":Vector2(-188, 413)},
		{"emoji":"🌺","label":"Цветник","w":58,"h":20,"color":Color(0.68,0.22,0.38),"pos":Vector2(  14, 396)},

		# ══ ЮЗ: УНИВЕРСИТЕТСКИЙ КАМПУС (x≈-1050 до -430, y≈+620 до +960) ══
		{"emoji":"🏛","label":"Корпус А\nУниверситет","w":192,"h":148,"color":Color(0.36,0.42,0.62),"pos":Vector2(-1000, 730)},
		{"emoji":"🏛","label":"Корпус Б\nФакультет",  "w":162,"h":128,"color":Color(0.34,0.40,0.60),"pos":Vector2( -740, 745)},
		{"emoji":"🏛","label":"Библиотека",            "w":145,"h":108,"color":Color(0.38,0.44,0.64),"pos":Vector2( -520, 750)},
		{"emoji":"🌲","label":"",                      "w":42,"h":42,"color":Color(0.15,0.45,0.17),"pos":Vector2(-1000, 900)},
		{"emoji":"🌲","label":"",                      "w":42,"h":42,"color":Color(0.17,0.47,0.19),"pos":Vector2( -875, 910)},
		{"emoji":"🌲","label":"",                      "w":40,"h":40,"color":Color(0.15,0.45,0.17),"pos":Vector2( -730, 920)},
		{"emoji":"🌲","label":"",                      "w":40,"h":40,"color":Color(0.17,0.47,0.19),"pos":Vector2( -600, 910)},
		{"emoji":"🌲","label":"",                      "w":38,"h":38,"color":Color(0.15,0.45,0.17),"pos":Vector2( -470, 900)},

		# ══ ЮВ: ТОРГОВО-СЕРВИСНАЯ ЗОНА (x≈+350 до +1000, y≈+560 до +960) ══
		{"emoji":"🏬","label":"ТЦ «Галерея»","w":235,"h":158,"color":Color(0.42,0.50,0.58),"pos":Vector2( 720, 760)},
		{"emoji":"🏪","label":"Супермаркет", "w":135,"h": 95,"color":Color(0.38,0.46,0.52),"pos":Vector2( 440, 765)},
		{"emoji":"🏪","label":"Магазины",    "w":115,"h": 82,"color":Color(0.36,0.44,0.50),"pos":Vector2( 440, 878)},
		{"emoji":"🚗","label":"Авторынок",   "w":125,"h": 85,"color":Color(0.30,0.28,0.26),"pos":Vector2( 950, 620)},
		{"emoji":"🚗","label":"Шоурум",      "w":108,"h": 72,"color":Color(0.28,0.26,0.24),"pos":Vector2( 950, 735)},

		# ══ СТАДИОН «СПАРТАК» (ЮЗ, рядом с фитнесом) ══
		{"emoji":"🏟","label":"Стадион\n«Спартак»","w":188,"h":160,"color":Color(0.40,0.36,0.52),"pos":Vector2(-360, 790)},

		# ══ АЗС, ПАРКОВКИ ══
		{"emoji":"⛽","label":"АЗС Лукойл", "w":92,"h":62,"color":Color(0.52,0.42,0.16),"pos":Vector2(-900, 310)},
		{"emoji":"🅿","label":"P1",          "w":178,"h":56,"color":Color(0.20,0.20,0.22),"pos":Vector2(-900,-255)},
		{"emoji":"🅿","label":"P2",          "w":158,"h":52,"color":Color(0.20,0.20,0.22),"pos":Vector2( 950,-168)},
		{"emoji":"🅿","label":"P3 ТЦ",       "w":225,"h":62,"color":Color(0.20,0.20,0.22),"pos":Vector2( 480, 655)},
		{"emoji":"🅿","label":"P4",          "w":158,"h":52,"color":Color(0.20,0.20,0.22),"pos":Vector2( 950, 520)},

		# ══ ДЕРЕВЬЯ ВДОЛЬ БУЛ.ЦЕНТРАЛЬНОГО (y≈-680 и -612) ══
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.17,0.47,0.19),"pos":Vector2(-1050,-680)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.19,0.49,0.21),"pos":Vector2( -830,-680)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.17,0.47,0.19),"pos":Vector2( -600,-680)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.19,0.49,0.21),"pos":Vector2( -350,-680)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.17,0.47,0.19),"pos":Vector2(  -80,-680)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.19,0.49,0.21),"pos":Vector2(  190,-680)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.17,0.47,0.19),"pos":Vector2(  450,-680)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.19,0.49,0.21),"pos":Vector2(  700,-680)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.17,0.45,0.17),"pos":Vector2(-1050,-608)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.19,0.47,0.19),"pos":Vector2( -820,-608)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.17,0.45,0.17),"pos":Vector2( -580,-608)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.19,0.47,0.19),"pos":Vector2( -330,-608)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.17,0.45,0.17),"pos":Vector2(  -55,-608)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.19,0.47,0.19),"pos":Vector2(  210,-608)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.17,0.45,0.17),"pos":Vector2(  470,-608)},

		# ══ ДЕРЕВЬЯ ВДОЛЬ УЛ.СОВЕТСКОЙ (y≈+48 и +152) ══
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.18,0.48,0.20),"pos":Vector2(-1050,  48)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.50,0.22),"pos":Vector2( -815,  48)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.18,0.48,0.20),"pos":Vector2( -555,  48)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.50,0.22),"pos":Vector2( -265,  48)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.18,0.48,0.20),"pos":Vector2(   90,  48)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.50,0.22),"pos":Vector2(  380,  48)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.18,0.48,0.20),"pos":Vector2(  700,  48)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.18,0.48,0.20),"pos":Vector2(-1050, 152)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.50,0.22),"pos":Vector2( -810, 152)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.18,0.48,0.20),"pos":Vector2( -540, 152)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.50,0.22),"pos":Vector2( -250, 152)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.18,0.48,0.20),"pos":Vector2(  100, 152)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.20,0.50,0.22),"pos":Vector2(  390, 152)},
		{"emoji":"🌳","label":"","w":30,"h":30,"color":Color(0.18,0.48,0.20),"pos":Vector2(  710, 152)},

		# ══ ДЕРЕВЬЯ ВДОЛЬ ПР.УНИВЕРСИТЕТСКОГО (x≈-375 и -300) ══
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.46,0.18),"pos":Vector2(-375,-960)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.48,0.20),"pos":Vector2(-375,-700)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.46,0.18),"pos":Vector2(-375,-440)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.48,0.20),"pos":Vector2(-375,-200)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.46,0.18),"pos":Vector2(-375, 200)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.48,0.20),"pos":Vector2(-300,-960)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.46,0.18),"pos":Vector2(-300,-700)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.48,0.20),"pos":Vector2(-300,-440)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.46,0.18),"pos":Vector2(-300,-200)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.48,0.20),"pos":Vector2(-300, 200)},

		# ══ ДЕРЕВЬЯ ВДОЛЬ УЛ.ТОРГОВОЙ (x≈+570 и +648) ══
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.46,0.18),"pos":Vector2( 570,-960)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.48,0.20),"pos":Vector2( 570,-700)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.46,0.18),"pos":Vector2( 570,-430)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.48,0.20),"pos":Vector2( 570,-150)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.46,0.18),"pos":Vector2( 648,-960)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.48,0.20),"pos":Vector2( 648,-700)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.18,0.46,0.18),"pos":Vector2( 648,-430)},
		{"emoji":"🌳","label":"","w":28,"h":28,"color":Color(0.20,0.48,0.20),"pos":Vector2( 648,-150)},

		# ══ ОСТАНОВКИ ══
		{"emoji":"🚌","label":"ост. Деловой бульвар", "w":62,"h":22,"color":Color(0.25,0.40,0.60),"pos":Vector2(   0,-708)},
		{"emoji":"🚌","label":"ост. Центральный парк", "w":62,"h":22,"color":Color(0.25,0.40,0.60),"pos":Vector2(   0, 308)},
		{"emoji":"🚌","label":"ост. ТЦ Галерея",       "w":62,"h":22,"color":Color(0.25,0.40,0.60),"pos":Vector2( 520, 648)},
		{"emoji":"🚌","label":"ост. Университет",       "w":62,"h":22,"color":Color(0.25,0.40,0.60),"pos":Vector2(-700, 648)},
	],
	# Зона 4 — Бизнес-квартал (финансовые башни, площадь Капитала)
	# Интерактивные: Биржа(-800,-300)  Офис-центр(700,-400)   Технопарк(-200,-700)
	#                Торговый зал(600,-200)  Венчурный фонд(800,-600)  Конгресс-холл(-800,400)
	#                Бизнес-кафе(-250,-150)  Ресторан(-600,500)  Фитнес Premium(300,650)
	#                Мэрия(500,-600)  Клиника(800,400)  Магистратура(-900,500)  Тур.фирма(0,250)
	[
		# ══ СЕВЕР: ФИНАНСОВЫЙ РАЙОН ══
		{"emoji":"🚁","label":"VIP-Вертодром","w":58,"h":42,"color":Color(0.28,0.28,0.38),"pos":Vector2(-480,-968)},
		# ══ СЗ: ОФИСНЫЙ КЛАСТЕР ══
		{"emoji":"🏢","label":"БЦ «Атлас»\n18эт",  "w":148,"h":182,"color":Color(0.28,0.38,0.60),"pos":Vector2(-975,-608)},
		{"emoji":"🏢","label":"БЦ «Юпитер»\n15эт", "w":132,"h":160,"color":Color(0.26,0.36,0.56),"pos":Vector2(-975,-382)},
		{"emoji":"🏢","label":"БЦ «Сатурн»\n12эт", "w":125,"h":145,"color":Color(0.30,0.40,0.60),"pos":Vector2(-975,-178)},
		# ══ СВ: БАНКОВСКИЙ КВАРТАЛ ══
		{"emoji":"🏛","label":"ЦБ РФ",           "w":165,"h":130,"color":Color(0.34,0.44,0.64),"pos":Vector2( 970,-625)},
		{"emoji":"🏢","label":"Сбербанк\n22эт",  "w":138,"h":170,"color":Color(0.15,0.36,0.22),"pos":Vector2( 970,-442)},
		{"emoji":"🏢","label":"ВТБ Банк\n18эт",  "w":128,"h":154,"color":Color(0.14,0.22,0.50),"pos":Vector2( 970,-248)},
		# ══ ЦЕНТР: ПЛОЩАДЬ КАПИТАЛА ══
		{"emoji":"⛲","label":"Фонтан «Успех»",  "w":92,"h":92,"color":Color(0.16,0.42,0.80),"pos":Vector2(   0, -22)},
		{"emoji":"🗿","label":"«Бык и Медведь»", "w":44,"h":95,"color":Color(0.42,0.38,0.28),"pos":Vector2(-168,  14)},
		{"emoji":"🗿","label":"Статуя",          "w":35,"h":84,"color":Color(0.43,0.40,0.36),"pos":Vector2( 165,  14)},
		{"emoji":"🚩","label":"Флаг РФ","w":12,"h":62,"color":Color(0.12,0.35,0.74),"pos":Vector2(-115, -58)},
		{"emoji":"🚩","label":"Флаг РФ","w":12,"h":62,"color":Color(0.12,0.35,0.74),"pos":Vector2( 115, -58)},
		{"emoji":"🌺","label":"Цветник", "w":55,"h":22,"color":Color(0.18,0.50,0.22),"pos":Vector2(-290, -32)},
		{"emoji":"🌺","label":"Цветник", "w":55,"h":22,"color":Color(0.20,0.52,0.20),"pos":Vector2( 200, -32)},
		{"emoji":"🌺","label":"Цветник", "w":55,"h":22,"color":Color(0.18,0.50,0.22),"pos":Vector2(-290, 138)},
		{"emoji":"🌺","label":"Цветник", "w":55,"h":22,"color":Color(0.20,0.52,0.20),"pos":Vector2( 200, 138)},
		{"emoji":"🪑","label":"Скамья","w":44,"h":18,"color":Color(0.38,0.32,0.22),"pos":Vector2(-235, 62)},
		{"emoji":"🪑","label":"Скамья","w":44,"h":18,"color":Color(0.38,0.32,0.22),"pos":Vector2( 145, 62)},
		{"emoji":"🪑","label":"Скамья","w":44,"h":18,"color":Color(0.38,0.32,0.22),"pos":Vector2(-235,132)},
		{"emoji":"🪑","label":"Скамья","w":44,"h":18,"color":Color(0.38,0.32,0.22),"pos":Vector2( 145,132)},
		{"emoji":"🗺","label":"Карта\nрайона","w":32,"h":52,"color":Color(0.30,0.36,0.50),"pos":Vector2(-305, 62)},
		{"emoji":"🗺","label":"Карта\nрайона","w":32,"h":52,"color":Color(0.30,0.36,0.50),"pos":Vector2( 235, 62)},
		# ══ ПР. ФИНАНСОВЫЙ: сервисы ══
		{"emoji":"💊","label":"Аптека 24ч","w":85,"h":65,"color":Color(0.18,0.55,0.38),"pos":Vector2( 200,-400)},
		{"emoji":"📱","label":"Связной",  "w":78,"h":62,"color":Color(0.22,0.28,0.56),"pos":Vector2( 322,-400)},
		{"emoji":"🏧","label":"Банкомат", "w":38,"h":48,"color":Color(0.26,0.36,0.62),"pos":Vector2( 462,-400)},
		{"emoji":"🏧","label":"Банкомат", "w":38,"h":48,"color":Color(0.26,0.36,0.62),"pos":Vector2(-458,-400)},
		# ══ ЗАПАД: ОТЕЛЬ И КОНГРЕСС-ХОЛЛ ══
		{"emoji":"🏨","label":"Отель «Ренессанс»\n25эт","w":158,"h":198,"color":Color(0.35,0.28,0.46),"pos":Vector2(-975, 132)},
		# ══ ВОСТОК: МЕДЦЕНТР И IT-ХАБ ══
		{"emoji":"🏥","label":"Медцентр «Ваш доктор»","w":155,"h":120,"color":Color(0.22,0.52,0.52),"pos":Vector2( 970, 278)},
		{"emoji":"🏢","label":"IT-Хаб «Data Park»",   "w":140,"h":110,"color":Color(0.20,0.30,0.54),"pos":Vector2( 970, 445)},
		# ══ ЮГ: ТОРГОВЛЯ И РАЗВЛЕЧЕНИЯ ══
		{"emoji":"🏬","label":"Бизнес-Молл «Метрополис»","w":258,"h":160,"color":Color(0.36,0.44,0.56),"pos":Vector2( 718, 735)},
		{"emoji":"🏨","label":"Бутик-Отель",              "w":135,"h":118,"color":Color(0.42,0.32,0.48),"pos":Vector2( 442, 736)},
		{"emoji":"🎬","label":"Кинотеатр «IMAX»",        "w":178,"h":120,"color":Color(0.22,0.22,0.32),"pos":Vector2(-502, 748)},
		{"emoji":"🍕","label":"Ресторан улицы",           "w":118,"h": 90,"color":Color(0.50,0.30,0.18),"pos":Vector2(-762, 750)},
		# ══ СТОЯНКИ И АЗС ══
		{"emoji":"🅿","label":"Паркинг P1 Подземный","w":238,"h":72,"color":Color(0.20,0.20,0.24),"pos":Vector2(   0, 848)},
		{"emoji":"🅿","label":"P2",                  "w":150,"h":58,"color":Color(0.20,0.20,0.24),"pos":Vector2(-925, 850)},
		{"emoji":"🅿","label":"P3 VIP",              "w":128,"h":52,"color":Color(0.22,0.22,0.28),"pos":Vector2( 970, 600)},
		{"emoji":"⛽","label":"АЗС Shell",           "w":86,"h":66,"color":Color(0.58,0.48,0.10),"pos":Vector2(-722, 842)},
		# ══ СТРОЯЩИЙСЯ ОБЪЕКТ И АТМОСФЕРА ══
		{"emoji":"🏗","label":"Башня «Зенит»\nСтр-во, 52эт", "w":108,"h":80,"color":Color(0.26,0.30,0.42),"pos":Vector2( 750,-860)},
		{"emoji":"🚧","label":"Стройзона", "w":112,"h":18,"color":Color(0.55,0.45,0.08),"pos":Vector2( 750,-780)},
		{"emoji":"🏅","label":"Forbes\nTop-100", "w":68,"h":52,"color":Color(0.38,0.30,0.08),"pos":Vector2(-162,-480)},
		# ══ DIGITAL-БИЛЛБОРДЫ ══
		{"emoji":"📺","label":"MOEX +2.4%\nSBER ▲  YNDX ▲","w":85,"h":38,"color":Color(0.08,0.14,0.30),"pos":Vector2(-180,-435)},
		{"emoji":"📺","label":"USD/RUB\n89.42 ▼",           "w":75,"h":34,"color":Color(0.08,0.16,0.28),"pos":Vector2( 250,-435)},
		{"emoji":"📺","label":"ЦБ РФ\nСтавка 5%",          "w":70,"h":32,"color":Color(0.10,0.18,0.32),"pos":Vector2(-640,-435)},
		{"emoji":"📺","label":"BTC ▲\n$67 420",            "w":70,"h":32,"color":Color(0.08,0.18,0.12),"pos":Vector2( 440,-435)},
		# ══ ОХРАНА И КПП ══
		{"emoji":"🚧","label":"КПП 1",    "w":50,"h":40,"color":Color(0.48,0.45,0.22),"pos":Vector2(-1042,-355)},
		{"emoji":"🚧","label":"КПП 2",    "w":50,"h":40,"color":Color(0.48,0.45,0.22),"pos":Vector2( 1042,-355)},
		{"emoji":"🚧","label":"Шлагбаум", "w":95,"h":12,"color":Color(0.74,0.14,0.14),"pos":Vector2(-1042,-322)},
		{"emoji":"🚧","label":"Шлагбаум", "w":95,"h":12,"color":Color(0.74,0.14,0.14),"pos":Vector2( 1042,-322)},
		# ══ ДЕРЕВЬЯ вдоль пр. Финансового ══
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.14,0.44,0.16),"pos":Vector2(-922,-382)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.16,0.46,0.18),"pos":Vector2(-682,-382)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.14,0.44,0.16),"pos":Vector2(-422,-382)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.16,0.46,0.18),"pos":Vector2(-142,-382)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.14,0.44,0.16),"pos":Vector2( 142,-382)},
		{"emoji":"🌲","label":"","w":32,"h":32,"color":Color(0.16,0.46,0.18),"pos":Vector2( 422,-382)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.14,0.44,0.16),"pos":Vector2( 652,-382)},
		# деревья вдоль Делового бульвара
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.14,0.42,0.16),"pos":Vector2(-922, 228)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.16,0.44,0.18),"pos":Vector2(-652, 228)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.14,0.42,0.16),"pos":Vector2(-362, 228)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.16,0.44,0.18),"pos":Vector2(-102, 228)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.14,0.42,0.16),"pos":Vector2( 182, 228)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.16,0.44,0.18),"pos":Vector2( 452, 228)},
		{"emoji":"🌲","label":"","w":30,"h":30,"color":Color(0.14,0.42,0.16),"pos":Vector2( 702, 228)},
		# деревья у площади Капитала
		{"emoji":"🌳","label":"","w":40,"h":40,"color":Color(0.16,0.48,0.18),"pos":Vector2(-322, -82)},
		{"emoji":"🌳","label":"","w":40,"h":40,"color":Color(0.18,0.50,0.20),"pos":Vector2( 252, -88)},
		{"emoji":"🌳","label":"","w":38,"h":38,"color":Color(0.16,0.48,0.18),"pos":Vector2(-322,  172)},
		{"emoji":"🌳","label":"","w":38,"h":38,"color":Color(0.18,0.50,0.20),"pos":Vector2( 252,  172)},
		# деревья у южного молла
		{"emoji":"🌲","label":"","w":28,"h":28,"color":Color(0.14,0.42,0.16),"pos":Vector2(-922, 648)},
		{"emoji":"🌲","label":"","w":28,"h":28,"color":Color(0.16,0.44,0.18),"pos":Vector2(-652, 648)},
		{"emoji":"🌲","label":"","w":28,"h":28,"color":Color(0.14,0.42,0.16),"pos":Vector2( 282, 648)},
		{"emoji":"🌲","label":"","w":28,"h":28,"color":Color(0.16,0.44,0.18),"pos":Vector2( 552, 648)},
		# ══ АВТОБУСНЫЕ ОСТАНОВКИ ══
		{"emoji":"🚌","label":"ост. Финансовая",  "w":68,"h":22,"color":Color(0.28,0.44,0.64),"pos":Vector2(   0,-445)},
		{"emoji":"🚌","label":"ост. Пл.Капитала", "w":68,"h":22,"color":Color(0.28,0.44,0.64),"pos":Vector2(   0, 222)},
		{"emoji":"🚌","label":"ост. Бизнес-Молл", "w":68,"h":22,"color":Color(0.28,0.44,0.64),"pos":Vector2(   0, 848)},
		{"emoji":"🚌","label":"ост. Биржевая",     "w":68,"h":22,"color":Color(0.28,0.44,0.64),"pos":Vector2(   0,-855)},
	],
	# Зона 5 — Элитный район (виллы, особняки, сады, бассейны)
	# Интерактивные: Яхт-клуб(-800,-300) Аэропорт(700,-400) Казино(-500,500)
	#                Агентство(500,-600) Частная клиника(800,400) Аспирантура(-900,500) Тур.фирма(0,250)
	[
		# ══ ОСОБНЯКИ СЕВЕР (y≈-700 до -900) ══
		{"emoji":"🏰","label":"Особняк А","w":165,"h":135,"color":Color(0.56,0.51,0.38),"pos":Vector2(-700,-800)},
		{"emoji":"🏰","label":"Особняк Б","w":160,"h":130,"color":Color(0.54,0.49,0.36),"pos":Vector2(-400,-800)},
		{"emoji":"🏰","label":"Особняк В","w":155,"h":128,"color":Color(0.58,0.53,0.40),"pos":Vector2(-100,-780)},
		{"emoji":"🏰","label":"Особняк Г","w":160,"h":130,"color":Color(0.54,0.49,0.36),"pos":Vector2( 250,-800)},
		# ══ ВИЛЛЫ ЗАПАД (x≈-900) ══
		{"emoji":"🏡","label":"Вилла 1","w":130,"h":110,"color":Color(0.58,0.52,0.40),"pos":Vector2(-900,-530)},
		{"emoji":"🏡","label":"Вилла 2","w":125,"h":105,"color":Color(0.56,0.50,0.38),"pos":Vector2(-900,-350)},
		# ══ ЧАСТНЫЕ САДЫ И БАССЕЙНЫ (центр-юг) ══
		{"emoji":"🏊","label":"Бассейн",  "w":110,"h":65,"color":Color(0.12,0.38,0.70),"pos":Vector2(-230, 720)},
		{"emoji":"🏊","label":"Бассейн",  "w": 95,"h":58,"color":Color(0.10,0.36,0.68),"pos":Vector2( 220, 730)},
		{"emoji":"🌳","label":"Сад",     "w":75,"h":75,"color":Color(0.15,0.45,0.18),"pos":Vector2( -80, 720)},
		{"emoji":"🌳","label":"",        "w":70,"h":70,"color":Color(0.17,0.47,0.20),"pos":Vector2(  40, 760)},
		{"emoji":"🌳","label":"",        "w":65,"h":65,"color":Color(0.16,0.46,0.19),"pos":Vector2(-180, 790)},
		{"emoji":"🌳","label":"",        "w":70,"h":70,"color":Color(0.15,0.45,0.18),"pos":Vector2( 140, 800)},
		# ══ ТЕАТР И СОБОР (ЮВ и ЮЗ) ══
		{"emoji":"🎭","label":"Театр",  "w":185,"h":135,"color":Color(0.45,0.35,0.55),"pos":Vector2( 800, 820)},
		{"emoji":"⛪","label":"Собор",  "w":115,"h":145,"color":Color(0.83,0.81,0.76),"pos":Vector2(-800, 820)},
		# ══ ВЕРТОЛЁТНАЯ ПЛОЩАДКА (СВ угол) ══
		{"emoji":"🚁","label":"Вертолёт","w":75,"h":55,"color":Color(0.35,0.35,0.40),"pos":Vector2( 900,-180)},
		# ══ ЗАБОРЫ И ОГРАДЫ ВИЛЛ ══
		{"emoji":"🚧","label":"Ограда", "w":300,"h":12,"color":Color(0.62,0.58,0.42),"pos":Vector2(-900,-660)},
		{"emoji":"🚧","label":"Ограда", "w":300,"h":12,"color":Color(0.62,0.58,0.42),"pos":Vector2(-560,-660)},
		# ══ ДЕРЕВЬЯ вдоль аллей ══
		{"emoji":"🌲","label":"","w":38,"h":38,"color":Color(0.14,0.43,0.17),"pos":Vector2(-900,-640)},
		{"emoji":"🌲","label":"","w":38,"h":38,"color":Color(0.16,0.45,0.19),"pos":Vector2(-680,-640)},
		{"emoji":"🌲","label":"","w":38,"h":38,"color":Color(0.14,0.43,0.17),"pos":Vector2(-450,-640)},
		{"emoji":"🌲","label":"","w":38,"h":38,"color":Color(0.16,0.45,0.19),"pos":Vector2(-200,-640)},
		{"emoji":"🌲","label":"","w":38,"h":38,"color":Color(0.14,0.43,0.17),"pos":Vector2(  80,-640)},
		{"emoji":"🌲","label":"","w":35,"h":35,"color":Color(0.13,0.42,0.16),"pos":Vector2( 900,-600)},
		{"emoji":"🌲","label":"","w":35,"h":35,"color":Color(0.15,0.44,0.18),"pos":Vector2( 900,-200)},
		# ══ ОСТАНОВКА ══
		{"emoji":"🚌","label":"ост. Элитная","w":58,"h":22,"color":Color(0.30,0.45,0.62),"pos":Vector2(  0,-800)},
	],
	# Зона 6 — Район олигархов (дворцы, частные аэропорты, нефтяные вышки)
	# Интерактивные: Дворец(-800,-300) Частный аэропорт(700,-400) Нефтяная вышка(-600,500)
	#                Опера(700,500) Офшор(500,-600) НИИ(-900,500) Казино VIP(-400,-500) Тур.фирма(0,250)
	[
		# ══ ДВОРЦЫ И ЗАМКИ СЕВЕР (y≈-750 до -950) ══
		{"emoji":"🏯","label":"Дворец А","w":205,"h":165,"color":Color(0.56,0.51,0.25),"pos":Vector2(-700,-840)},
		{"emoji":"🏯","label":"Дворец Б","w":200,"h":160,"color":Color(0.53,0.48,0.23),"pos":Vector2(-380,-840)},
		{"emoji":"🏰","label":"Замок",   "w":175,"h":185,"color":Color(0.50,0.46,0.22),"pos":Vector2(  50,-870)},
		{"emoji":"🏰","label":"Замок",   "w":170,"h":180,"color":Color(0.48,0.44,0.20),"pos":Vector2( 380,-850)},
		# ══ РЕЗИДЕНЦИИ ЗАПАД ══
		{"emoji":"🏡","label":"Резиденция","w":155,"h":135,"color":Color(0.58,0.54,0.30),"pos":Vector2(-900,-530)},
		{"emoji":"🏡","label":"Резиденция","w":150,"h":130,"color":Color(0.56,0.52,0.28),"pos":Vector2(-900,-350)},
		# ══ АНГАР ЧАСТНОГО АЭРОПОРТА (СВ) ══
		{"emoji":"🛩","label":"Ангар А","w":190,"h":115,"color":Color(0.30,0.30,0.38),"pos":Vector2( 850,-180)},
		{"emoji":"🛩","label":"Ангар Б","w":165,"h":100,"color":Color(0.28,0.28,0.36),"pos":Vector2( 850,  50)},
		# ══ СОБОР И ПАРК (ЮЗ) ══
		{"emoji":"⛪","label":"Собор",  "w":135,"h":165,"color":Color(0.86,0.83,0.76),"pos":Vector2(-900, 820)},
		{"emoji":"🌳","label":"Парк",  "w":80,"h":80,"color":Color(0.14,0.42,0.16),"pos":Vector2(-220, 720)},
		{"emoji":"🌳","label":"",      "w":75,"h":75,"color":Color(0.16,0.44,0.18),"pos":Vector2(-100, 760)},
		{"emoji":"🌳","label":"",      "w":80,"h":80,"color":Color(0.15,0.43,0.17),"pos":Vector2(-340, 750)},
		{"emoji":"🌳","label":"",      "w":70,"h":70,"color":Color(0.14,0.42,0.16),"pos":Vector2(-220, 810)},
		# ══ БАССЕЙН VIP ══
		{"emoji":"🏊","label":"Бассейн VIP","w":130,"h":75,"color":Color(0.08,0.33,0.72),"pos":Vector2( 280, 720)},
		# ══ ЗОЛОТЫЕ ВОРОТА ══
		{"emoji":"🚧","label":"Ворота","w":12,"h":120,"color":Color(0.72,0.60,0.15),"pos":Vector2(-260,-650)},
		{"emoji":"🚧","label":"Ворота","w":12,"h":120,"color":Color(0.72,0.60,0.15),"pos":Vector2( 260,-650)},
		# ══ ДЕРЕВЬЯ ══
		{"emoji":"🌲","label":"","w":40,"h":40,"color":Color(0.14,0.43,0.17),"pos":Vector2(-900,-660)},
		{"emoji":"🌲","label":"","w":40,"h":40,"color":Color(0.16,0.45,0.19),"pos":Vector2(-640,-660)},
		{"emoji":"🌲","label":"","w":40,"h":40,"color":Color(0.14,0.43,0.17),"pos":Vector2(-340,-660)},
		{"emoji":"🌲","label":"","w":40,"h":40,"color":Color(0.16,0.45,0.19),"pos":Vector2(  -20,-660)},
		{"emoji":"🌲","label":"","w":35,"h":35,"color":Color(0.13,0.42,0.16),"pos":Vector2( 500, 820)},
		{"emoji":"🌲","label":"","w":35,"h":35,"color":Color(0.15,0.44,0.18),"pos":Vector2( 700, 820)},
	],
	# Зона 7 — Правительственный квартал (министерства, парламент, охрана, КПП)
	# Интерактивные: Минфин(-800,-300) Госбанк(700,-400) Посольство(-600,500)
	#                Совет директоров(700,500) VIP-Клиника(900,300) Академия(-900,500)
	#                Налог.служба(500,-600) Тур.фирма(0,250)
	[
		# ══ ПАРЛАМЕНТ И МИНИСТЕРСТВА СЕВЕР (y≈-700 до -900) ══
		{"emoji":"🏛","label":"Парламент",      "w":215,"h":155,"color":Color(0.35,0.40,0.58),"pos":Vector2(   0,-840)},
		{"emoji":"🏛","label":"Министерство А", "w":180,"h":140,"color":Color(0.30,0.35,0.52),"pos":Vector2(-700,-750)},
		{"emoji":"🏛","label":"Министерство Б", "w":175,"h":135,"color":Color(0.28,0.33,0.50),"pos":Vector2(-400,-750)},
		{"emoji":"🏛","label":"Министерство В", "w":170,"h":132,"color":Color(0.32,0.37,0.54),"pos":Vector2( 350,-750)},
		{"emoji":"🏢","label":"Ведомство А",    "w":140,"h":112,"color":Color(0.32,0.38,0.55),"pos":Vector2(-900,-580)},
		{"emoji":"🏢","label":"Ведомство Б",    "w":135,"h":108,"color":Color(0.30,0.36,0.53),"pos":Vector2( 850,-580)},
		# ══ КПП И ОХРАНА (по периметру) ══
		{"emoji":"🚧","label":"КПП-1","w":65,"h":42,"color":Color(0.50,0.45,0.20),"pos":Vector2(-900,-150)},
		{"emoji":"🚧","label":"КПП-2","w":65,"h":42,"color":Color(0.50,0.45,0.20),"pos":Vector2( 900,-150)},
		{"emoji":"🚧","label":"КПП-3","w":65,"h":42,"color":Color(0.50,0.45,0.20),"pos":Vector2(   0,-650)},
		# ══ МОНУМЕНТЫ И ПАМЯТНИКИ ══
		{"emoji":"🗿","label":"Монумент\nПобеды","w":55,"h":130,"color":Color(0.56,0.53,0.46),"pos":Vector2(-900, 820)},
		{"emoji":"🗿","label":"Монумент",        "w":45,"h":110,"color":Color(0.54,0.51,0.44),"pos":Vector2( 250, 820)},
		# ══ СОБОР (ЮВ) ══
		{"emoji":"⛪","label":"Собор",    "w":115,"h":145,"color":Color(0.83,0.81,0.75),"pos":Vector2( 850, 820)},
		# ══ ВЕРТОЛЁТНАЯ ПЛОЩАДКА ══
		{"emoji":"🚁","label":"Площадка","w":80,"h":60,"color":Color(0.30,0.30,0.38),"pos":Vector2( 850, 130)},
		# ══ ПРАВИТЕЛЬСТВЕННЫЙ ПАРК (центр) ══
		{"emoji":"🌳","label":"Парк Победы","w":70,"h":70,"color":Color(0.14,0.42,0.16),"pos":Vector2(-220, 720)},
		{"emoji":"🌳","label":"",           "w":65,"h":65,"color":Color(0.16,0.44,0.18),"pos":Vector2(-100, 760)},
		{"emoji":"🌳","label":"",           "w":70,"h":70,"color":Color(0.15,0.43,0.17),"pos":Vector2(-340, 750)},
		{"emoji":"🌳","label":"",           "w":65,"h":65,"color":Color(0.14,0.42,0.16),"pos":Vector2(-220, 810)},
		# ══ КОРТЕЖИ ══
		{"emoji":"🚗","label":"Кортеж","w":85,"h":48,"color":Color(0.10,0.10,0.12),"pos":Vector2( 300, 150)},
		{"emoji":"🚗","label":"Кортеж","w":85,"h":48,"color":Color(0.10,0.10,0.12),"pos":Vector2(-300, 820)},
		# ══ ДЕРЕВЬЯ ══
		{"emoji":"🌲","label":"","w":35,"h":35,"color":Color(0.14,0.43,0.17),"pos":Vector2(-900,-660)},
		{"emoji":"🌲","label":"","w":35,"h":35,"color":Color(0.16,0.45,0.19),"pos":Vector2(-600,-660)},
		{"emoji":"🌲","label":"","w":35,"h":35,"color":Color(0.14,0.43,0.17),"pos":Vector2(-300,-660)},
		{"emoji":"🌲","label":"","w":35,"h":35,"color":Color(0.16,0.45,0.19),"pos":Vector2(  50,-660)},
		{"emoji":"🌲","label":"","w":35,"h":35,"color":Color(0.14,0.43,0.17),"pos":Vector2( 400,-660)},
		# ══ ОСТАНОВКА ══
		{"emoji":"🚌","label":"ост. Правительственная","w":70,"h":22,"color":Color(0.28,0.42,0.58),"pos":Vector2(  0,-820)},
	],
	# Зона 8 — Высший свет: суперкомплекс власти и капитала
	# Интерактивные: Нефтекорпорация(-800,-300) Медиа-империя(700,-400) Госконтракт(-600,500)
	#                Казино-Роял(700,500) Частный банк(500,-600) Медцентр(900,300)
	#                НИИ Элит(-900,500) Тур.фирма(0,250)
	[
		# ══ РЕЗИДЕНЦИИ ПРАВИТЕЛЕЙ (север) ══
		{"emoji":"🏯","label":"Резиденция А","w":225,"h":175,"color":Color(0.22,0.22,0.30),"pos":Vector2(-700,-850)},
		{"emoji":"🏯","label":"Резиденция Б","w":220,"h":170,"color":Color(0.20,0.20,0.28),"pos":Vector2(-370,-840)},
		{"emoji":"🏯","label":"Резиденция В","w":215,"h":168,"color":Color(0.24,0.24,0.32),"pos":Vector2(  30,-860)},
		# ══ КОМПЛЕКСЫ БЕЗОПАСНОСТИ ══
		{"emoji":"🏰","label":"Комплекс А","w":185,"h":155,"color":Color(0.25,0.25,0.35),"pos":Vector2(-900, 820)},
		{"emoji":"🏰","label":"Комплекс Б","w":180,"h":150,"color":Color(0.23,0.23,0.33),"pos":Vector2( 850, 820)},
		# ══ АНГАРЫ VIP ══
		{"emoji":"🛩","label":"Ангар VIP А","w":195,"h":125,"color":Color(0.22,0.22,0.30),"pos":Vector2(-900, 100)},
		{"emoji":"🛩","label":"Ангар VIP Б","w":180,"h":115,"color":Color(0.20,0.20,0.28),"pos":Vector2(-900,-150)},
		# ══ БАССЕЙН EXECUTIVE ══
		{"emoji":"🏊","label":"Бассейн\nExec","w":140,"h":80,"color":Color(0.06,0.28,0.68),"pos":Vector2( 250, 720)},
		# ══ ЦЕНТР ВЛАСТИ (юг-центр) ══
		{"emoji":"⭐","label":"Центр\nвласти","w":210,"h":185,"color":Color(0.28,0.26,0.12),"pos":Vector2( 200, 840)},
		# ══ МОНУМЕНТЫ ══
		{"emoji":"🗼","label":"Игла","w":90,"h":215,"color":Color(0.32,0.30,0.16),"pos":Vector2( 850,-370)},
		# ══ ПАРК ПРАВИТЕЛЕЙ ══
		{"emoji":"🌳","label":"","w":80,"h":80,"color":Color(0.12,0.38,0.14),"pos":Vector2(-230, 720)},
		{"emoji":"🌳","label":"","w":75,"h":75,"color":Color(0.14,0.40,0.16),"pos":Vector2(-100, 760)},
		{"emoji":"🌳","label":"","w":80,"h":80,"color":Color(0.13,0.39,0.15),"pos":Vector2(-360, 750)},
		{"emoji":"🌳","label":"","w":70,"h":70,"color":Color(0.12,0.38,0.14),"pos":Vector2(-230, 820)},
		# ══ ДЕРЕВЬЯ ══
		{"emoji":"🌲","label":"","w":38,"h":38,"color":Color(0.12,0.40,0.14),"pos":Vector2(-900,-660)},
		{"emoji":"🌲","label":"","w":38,"h":38,"color":Color(0.14,0.42,0.16),"pos":Vector2(-580,-660)},
		{"emoji":"🌲","label":"","w":38,"h":38,"color":Color(0.12,0.40,0.14),"pos":Vector2(-240,-660)},
		{"emoji":"🌲","label":"","w":38,"h":38,"color":Color(0.14,0.42,0.16),"pos":Vector2( 100,-660)},
		# ══ ЗОЛОТЫЕ ВОРОТА КОМПЛЕКСА ══
		{"emoji":"🚧","label":"Ворота","w":14,"h":150,"color":Color(0.75,0.62,0.12),"pos":Vector2(-310,-660)},
		{"emoji":"🚧","label":"Ворота","w":14,"h":150,"color":Color(0.75,0.62,0.12),"pos":Vector2( 310,-660)},
		# ══ ВЕРТОДРОМ ══
		{"emoji":"🚁","label":"Вертодром","w":105,"h":65,"color":Color(0.18,0.18,0.22),"pos":Vector2( 200,-820)},
	],
]

# ─── Runtime ─────────────────────────────────────────────────────────────────
var _last_zone: int = -1
var _traffic_cars: Array = []
var _zm_cached: Node = null
var _player_cached: Node2D = null
var _zone_lock_overlays: Dictionary = {}

# Отсев далёких объектов. Вся карта (9 зон, ~15k узлов) загружена сразу, и рендер
# каждый кадр перебирает все CanvasItem. Поэтому всё, что дальше «обзора + размера»
# от игрока, прячем (visible=false — скрытое поддерево рендер не обходит) и переводим
# в PROCESS_MODE_DISABLED (стоп _process/физике/привязанным твинам). Карта-спан
# объекты (главные дороги) не отсеваются. Раскладку это не трогает — только видимость.
const CULL_VIEW: float = 1900.0   # половина обзора с запасом (учитывает зум-аут)
# Параллельные массивы (быстрее словарей в горячем цикле). Отсев инкрементальный:
# каждый кадр обрабатываем срез (~1/15 списка), без всплеска раз в 0.25 с.
var _cull_nodes: Array = []
var _cull_cx: PackedFloat32Array = PackedFloat32Array()
var _cull_cy: PackedFloat32Array = PackedFloat32Array()
var _cull_thr2: PackedFloat32Array = PackedFloat32Array()
var _cull_idx: int = 0

# ─── Анти-коллизия для зданий и жилых домов ──────────────────────────────────
# Дороги регистрируются первыми (_spawn_map_roads / _spawn_zoneN_streets),
# затем при спавне зданий/жилых домов проверяем пересечения и, если нужно,
# сдвигаем объект по спирали в ближайшее свободное место.
var _road_rects: Array = []    # Array[Rect2] — занятые дорогами участки
var _static_rects: Array = []  # Array[Rect2] — занятые зданиями/жильём участки

func _mark_road_rect(r: Control) -> void:
	_road_rects.append(Rect2(Vector2(r.offset_left, r.offset_top), Vector2(r.offset_right - r.offset_left, r.offset_bottom - r.offset_top)))

func _mark_road_from_posrect(r: Control) -> void:
	_road_rects.append(Rect2(r.position, r.size))

# ─── Визуал дороги: бесшовный асфальт тайлами, либо плоский цвет как запасной вариант ──
const TEX_ROAD_ASPHALT_PATH := "res://assets/textures/road_asphalt.png"

func _make_road_visual(fallback_col: Color) -> Control:
	if ResourceLoader.exists(TEX_ROAD_ASPHALT_PATH):
		var tr := TextureRect.new()
		tr.texture = load(TEX_ROAD_ASPHALT_PATH)
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tr
	var cr := ColorRect.new()
	cr.color = fallback_col
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cr

func _rect_is_free(rect: Rect2) -> bool:
	for r in _road_rects:
		if rect.intersects(r):
			return false
	for r in _static_rects:
		if rect.intersects(r):
			return false
	return true

# Подбирает безопасную позицию для здания/дома: не на дороге и не поверх
# другого здания. При конфликте ищет свободное место по спирали рядом с pos.
func _resolve_static_pos(pos: Vector2, w: float, h: float, margin: float = 6.0) -> Vector2:
	var size := Vector2(w, h) + Vector2(margin, margin) * 2.0
	var rect := Rect2(pos - size * 0.5, size)
	if _rect_is_free(rect):
		_static_rects.append(rect)
		return pos
	var step: float = maxf(w, h) * 0.5 + margin
	for ring in range(1, 10):
		var radius: float = step * ring
		var samples: int = 8 * ring
		for i in samples:
			var ang: float = TAU * float(i) / float(samples)
			var cand: Vector2 = pos + Vector2(cos(ang), sin(ang)) * radius
			var cand_rect := Rect2(cand - size * 0.5, size)
			if _rect_is_free(cand_rect):
				_static_rects.append(cand_rect)
				return cand
	# Свободного места не нашли — оставляем исходную позицию, но регистрируем,
	# чтобы следующие объекты хотя бы не наслаивались сверху на эту же точку.
	_static_rects.append(rect)
	return pos

# ═══════════════════════════════════════════════════════════════════════════════
var _canvas_modulate: CanvasModulate = null

func _ready() -> void:
	add_to_group("world")
	var zm: Node = get_node("/root/ZoneManager")

	$Background.visible = false  # старый одиночный фон не нужен

	_setup_day_night()
	_spawn_all_zone_backgrounds(zm)
	_spawn_map_roads()
	_spawn_zone0_streets()
	_spawn_zone2_streets()
	_spawn_zone0_parked_cars()
	_spawn_zone3_streets()
	_spawn_zone4_streets()
	_spawn_all_deco()
	_spawn_all_buildings()
	_spawn_all_npcs()
	_spawn_common_systems()
	_spawn_bus_stops()
	_spawn_bus_stop_ui()
	_spawn_outer_walls()
	_spawn_all_zone_parked_cars()
	_register_cullables()
	_spawn_road_traffic()
	_setup_camera_limits()
	_setup_zone_lock_overlays(zm)

	zm.zone_changed.connect(_on_zone_changed)

	# Виртуальный джойстик для тач / мобильных браузеров
	var joy_script = load("res://scripts/VirtualJoystick.gd")
	var joy = joy_script.new()
	add_child(joy)

	# Ставим игрока в центр текущей зоны
	var player_node = get_node_or_null("Player")
	if player_node:
		player_node.global_position = zm.get_zone_center(zm.current_zone) + Vector2(0, 150)

	_last_zone = zm.current_zone

# ─── Центр зоны в мировых координатах ───────────────────────────────────────
func _zone_center(z: int) -> Vector2:
	var g: Vector2i = ZoneManager.ZONE_GRID[z]
	return Vector2((g.x - 1) * ZONE_SIZE, (g.y - 1) * ZONE_SIZE)

# ─── Автоопределение зоны по позиции ─────────────────────────────────────────
func _pos_to_zone(pos: Vector2) -> int:
	var col: int = clamp(int(floor((pos.x + MAP_HALF) / ZONE_SIZE)), 0, 2)
	var row: int = clamp(int(floor((pos.y + MAP_HALF) / ZONE_SIZE)), 0, 2)
	var gp := Vector2i(col, row)
	for i in ZoneManager.ZONE_GRID.size():
		if ZoneManager.ZONE_GRID[i] == gp:
			return i
	return 0

func _process(delta: float) -> void:
	if _player_cached == null or not is_instance_valid(_player_cached):
		_player_cached = get_node_or_null("Player")
	if _player_cached == null:
		return
	var detected: int = _pos_to_zone(_player_cached.global_position)
	if detected != _last_zone:
		if _zm_cached == null:
			_zm_cached = get_node("/root/ZoneManager")
		_zm_cached.register_visit(detected)
		_last_zone = detected
		emit_signal("zone_auto_changed", detected)

	# Отсев далёких объектов — инкрементально, по срезу каждый кадр (без всплесков)
	_cull_step()

	# Движение дорожного трафика
	for tc in _traffic_cars:
		var nd = tc["node"]
		if not is_instance_valid(nd):
			continue
		if tc["axis"] == "x":
			nd.position.x += tc["speed"] * delta
			if nd.position.x > tc["max"]:
				nd.position.x = tc["min"]
			elif nd.position.x < tc["min"]:
				nd.position.x = tc["max"]
		else:
			nd.position.y += tc["speed"] * delta
			if nd.position.y > tc["max"]:
				nd.position.y = tc["min"]
			elif nd.position.y < tc["min"]:
				nd.position.y = tc["max"]

# Собирает все статичные визуальные узлы зон (здания, NPC, декор, фоны) с их
# центром и порогом дистанции. Карта-спан объекты (главные дороги) пропускаются —
# они должны быть видны всегда.
func _register_cullables() -> void:
	_cull_nodes.clear(); _cull_cx.clear(); _cull_cy.clear(); _cull_thr2.clear()
	for parent in [$Districts, $Buildings]:
		for child in parent.get_children():
			var radius := 110.0
			var cx: float = child.global_position.x
			var cy: float = child.global_position.y
			if child is Control:
				var sz: Vector2 = child.size
				var span: float = maxf(sz.x, sz.y)
				if span > ZONE_SIZE * 1.4:
					continue   # карта-спан (главные дороги/линии) — не отсеваем
				radius = span * 0.5 + 30.0
				cx += sz.x * 0.5
				cy += sz.y * 0.5
			var thr: float = CULL_VIEW + radius
			_cull_nodes.append(child)
			_cull_cx.append(cx)
			_cull_cy.append(cy)
			_cull_thr2.append(thr * thr)

# Один кадр отсева: обрабатываем срез списка от _cull_idx (без всплеска).
func _cull_step() -> void:
	var total: int = _cull_nodes.size()
	if total == 0 or _player_cached == null:
		return
	var px: float = _player_cached.global_position.x
	var py: float = _player_cached.global_position.y
	var batch: int = (total / 15) + 1
	for k in batch:
		var i: int = _cull_idx
		_cull_idx += 1
		if _cull_idx >= total:
			_cull_idx = 0
		_apply_cull(i, px, py)

# Полный проход (при телепорте — мгновенно обновить всю карту).
func _cull_all() -> void:
	if _player_cached == null:
		return
	var px: float = _player_cached.global_position.x
	var py: float = _player_cached.global_position.y
	for i in _cull_nodes.size():
		_apply_cull(i, px, py)

func _apply_cull(i: int, px: float, py: float) -> void:
	var node: Node = _cull_nodes[i]
	if not is_instance_valid(node):
		return
	var dx: float = px - _cull_cx[i]
	var dy: float = py - _cull_cy[i]
	var near: bool = (dx * dx + dy * dy) < _cull_thr2[i]
	if node.visible != near:
		node.visible = near
	var pm: int = PROCESS_MODE_INHERIT if near else PROCESS_MODE_DISABLED
	if node.process_mode != pm:
		node.process_mode = pm

signal zone_auto_changed(zone_index: int)

# ─── Внутренние улицы Трущоб ────────────────────────────────────────────────
func _spawn_zone0_streets() -> void:
	var c0: Vector2 = _zone_center(0)   # (-2500, -2500) в мировых координатах
	var road_col  := Color(0.16, 0.16, 0.16, 0.95)
	var W: float  = 1150.0              # полудлина улицы внутри зоны

	# Горизонтальные улицы
	var h_streets: Array = [
		{"y": -660.0, "name": "ул. Рассветная", "label_x": -1100.0},
		{"y":   80.0, "name": "ул. Мирная",     "label_x": -1100.0},
	]
	for s in h_streets:
		var wy: float = c0.y + s.y
		var road := _make_road_visual(road_col)
		road.offset_left   = c0.x - W
		road.offset_right  = c0.x + W
		road.offset_top    = wy - 34.0
		road.offset_bottom = wy + 34.0
		$Districts.add_child(road)
		_mark_road_rect(road)
		# Подпись улицы
		var lbl := Label.new()
		lbl.text = s.name
		lbl.position = Vector2(c0.x + s.label_x, wy - 30)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.55, 0.80))
		$Districts.add_child(lbl)

	# Конусы и пожарные гидранты на перекрёстках
	var intersections: Array = [
		Vector2(-720, -660), Vector2(-720,  80),
		Vector2( 250, -660), Vector2( 250,  80),
	]
	for ip in intersections:
		for offset in [Vector2(-45, -45), Vector2(45, -45), Vector2(-45, 45), Vector2(45, 45)]:
			var cone := Sprite2D.new()
			cone.texture = TEX_CONE
			cone.position = c0 + ip + offset
			cone.scale = Vector2(0.55, 0.55)
			$Districts.add_child(cone)

	# Пешеходные переходы (зебра) на перекрёстках
	for ip in intersections:
		for si in 7:
			var cb := ColorRect.new()
			cb.color = Color(0.96, 0.96, 0.93, 0.72)
			cb.offset_left   = c0.x + ip.x + 35.0 + si * 10.0
			cb.offset_right  = c0.x + ip.x + 40.0 + si * 10.0
			cb.offset_top    = c0.y + ip.y - 34.0
			cb.offset_bottom = c0.y + ip.y + 34.0
			$Districts.add_child(cb)
		for sj in 6:
			var cb2 := ColorRect.new()
			cb2.color = Color(0.96, 0.96, 0.93, 0.72)
			cb2.offset_left   = c0.x + ip.x - 30.0
			cb2.offset_right  = c0.x + ip.x + 30.0
			cb2.offset_top    = c0.y + ip.y + 38.0 + sj * 10.0
			cb2.offset_bottom = c0.y + ip.y + 43.0 + sj * 10.0
			$Districts.add_child(cb2)

	# Гидранты вдоль тротуаров (у аптеки, поликлиники, школы)
	var hydrant_spots: Array = [
		Vector2(-820, -630), Vector2(780, 155), Vector2(-350, -895)
	]
	for hp in hydrant_spots:
		var hyd := Sprite2D.new()
		hyd.texture = TEX_HYDRANT
		hyd.position = c0 + hp
		hyd.scale = Vector2(0.9, 0.9)
		$Districts.add_child(hyd)

	# Вертикальные улицы
	var v_streets: Array = [
		{"x": -720.0, "name": "пр. Северный",   "label_y": -1100.0},
		{"x":  250.0, "name": "ул. Берёзовая", "label_y": -1100.0},
	]
	for s in v_streets:
		var wx: float = c0.x + s.x
		var road := _make_road_visual(road_col)
		road.offset_left   = wx - 30.0
		road.offset_right  = wx + 30.0
		road.offset_top    = c0.y - W
		road.offset_bottom = c0.y + W
		$Districts.add_child(road)
		_mark_road_rect(road)
		var lbl := Label.new()
		lbl.text = s.name
		lbl.position = Vector2(wx + 35, c0.y + s.label_y)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.55, 0.80))
		$Districts.add_child(lbl)

	# Уличные фонари вдоль улиц Zone 0
	var lamp_col_pole := Color(0.30, 0.30, 0.35)
	var lamp_col_glow := Color(1.0, 0.92, 0.55, 0.28)
	var lamp_col_dot  := Color(1.0, 0.96, 0.72, 0.90)
	# Вдоль ул.Рассветной (y≈-660): фонари с севера (y≈-700)
	var lamp_xs_h: Array = [-1050, -850, -650, -430, -200, 30, 250, 480, 700, 920]
	for lx in lamp_xs_h:
		var ly: float = c0.y - 700.0
		var pole := ColorRect.new()
		pole.size = Vector2(4, 28); pole.position = Vector2(c0.x + lx - 2, ly - 30)
		pole.color = lamp_col_pole; $Districts.add_child(pole)
		var arm := ColorRect.new()
		arm.size = Vector2(10, 3); arm.position = Vector2(c0.x + lx - 10, ly - 30)
		arm.color = lamp_col_pole; $Districts.add_child(arm)
		var glow := ColorRect.new()
		glow.size = Vector2(20, 14); glow.position = Vector2(c0.x + lx - 18, ly - 44)
		glow.color = lamp_col_glow; $Districts.add_child(glow)
		var dot := ColorRect.new()
		dot.size = Vector2(8, 5); dot.position = Vector2(c0.x + lx - 12, ly - 41)
		dot.color = lamp_col_dot; $Districts.add_child(dot)
	# Вдоль ул.Мирной (y≈+80): фонари с юга (y≈+125)
	var lamp_xs_n: Array = [-1000, -780, -540, -280, 50, 300, 580, 820]
	for lx2 in lamp_xs_n:
		var ly2: float = c0.y + 125.0
		var pole2 := ColorRect.new()
		pole2.size = Vector2(4, 28); pole2.position = Vector2(c0.x + lx2 - 2, ly2 + 2)
		pole2.color = lamp_col_pole; $Districts.add_child(pole2)
		var arm2 := ColorRect.new()
		arm2.size = Vector2(10, 3); arm2.position = Vector2(c0.x + lx2 - 10, ly2 + 2)
		arm2.color = lamp_col_pole; $Districts.add_child(arm2)
		var glow2 := ColorRect.new()
		glow2.size = Vector2(20, 14); glow2.position = Vector2(c0.x + lx2 - 18, ly2 - 12)
		glow2.color = lamp_col_glow; $Districts.add_child(glow2)
		var dot2 := ColorRect.new()
		dot2.size = Vector2(8, 5); dot2.position = Vector2(c0.x + lx2 - 12, ly2 - 9)
		dot2.color = lamp_col_dot; $Districts.add_child(dot2)
	# Вдоль пр.Северного (x≈-720): фонари с востока (x≈-685)
	var lamp_ys_v: Array = [-1050, -820, -580, -340, -90, 160, 420, 680, 920]
	for ly3 in lamp_ys_v:
		var lx3: float = c0.x - 685.0
		var pole3 := ColorRect.new()
		pole3.size = Vector2(4, 28); pole3.position = Vector2(lx3 + 2, c0.y + ly3 - 2)
		pole3.color = lamp_col_pole; $Districts.add_child(pole3)
		var arm3 := ColorRect.new()
		arm3.size = Vector2(3, 10); arm3.position = Vector2(lx3 + 2, c0.y + ly3 - 14)
		arm3.color = lamp_col_pole; $Districts.add_child(arm3)
		var glow3 := ColorRect.new()
		glow3.size = Vector2(14, 20); glow3.position = Vector2(lx3 - 10, c0.y + ly3 - 24)
		glow3.color = lamp_col_glow; $Districts.add_child(glow3)
		var dot3 := ColorRect.new()
		dot3.size = Vector2(5, 8); dot3.position = Vector2(lx3 - 3, c0.y + ly3 - 20)
		dot3.color = lamp_col_dot; $Districts.add_child(dot3)

# ─── Улицы Бизнес-квартала (Зона 4) с фонарями и переходами ─────────────────
func _spawn_zone4_streets() -> void:
	var c4: Vector2 = _zone_center(4)   # (0, 0) в мировых координатах
	var road_col  := Color(0.13, 0.13, 0.15, 0.98)
	var side_col  := Color(0.20, 0.20, 0.24, 0.88)
	var plaza_col := Color(0.24, 0.24, 0.28, 0.72)
	var lamp_pole := Color(0.26, 0.28, 0.36)
	var lamp_glow := Color(0.65, 0.85, 1.00, 0.24)
	var lamp_dot  := Color(0.82, 0.95, 1.00, 0.94)
	var W: float  = 1150.0

	# ── Мощение площади Капитала ────────────────────────────────────────────
	var plazaB := ColorRect.new()
	plazaB.color = Color(0.30, 0.30, 0.36, 0.55)
	plazaB.offset_left = c4.x - 318.0; plazaB.offset_right = c4.x + 318.0
	plazaB.offset_top = c4.y - 128.0; plazaB.offset_bottom = c4.y + 150.0
	$Districts.add_child(plazaB)
	var plaza := ColorRect.new()
	plaza.color = plaza_col
	plaza.offset_left = c4.x - 312.0; plaza.offset_right = c4.x + 312.0
	plaza.offset_top = c4.y - 122.0; plaza.offset_bottom = c4.y + 144.0
	$Districts.add_child(plaza)

	# ── Горизонтальные проспекты с тротуарами ──────────────────────────────
	var h_data: Array = [
		{"y":-390.0,"name":"пр. Финансовый", "lx":-1130.0,"hw":42.0,"sw":14.0},
		{"y": 215.0,"name":"Деловой бульвар","lx":-1130.0,"hw":38.0,"sw":12.0},
	]
	for hs in h_data:
		var wy: float = c4.y + hs.y
		var hw: float = hs.hw; var sw: float = hs.sw
		var sw1 := ColorRect.new(); sw1.color = side_col
		sw1.offset_left = c4.x - W; sw1.offset_right = c4.x + W
		sw1.offset_top = wy - hw - sw; sw1.offset_bottom = wy - hw
		$Districts.add_child(sw1)
		var sw2 := ColorRect.new(); sw2.color = side_col
		sw2.offset_left = c4.x - W; sw2.offset_right = c4.x + W
		sw2.offset_top = wy + hw; sw2.offset_bottom = wy + hw + sw
		$Districts.add_child(sw2)
		var hroad := _make_road_visual(road_col)
		hroad.offset_left = c4.x - W; hroad.offset_right = c4.x + W
		hroad.offset_top = wy - hw; hroad.offset_bottom = wy + hw
		$Districts.add_child(hroad)
		_mark_road_rect(hroad)
		var hlbl := Label.new(); hlbl.text = hs.name
		hlbl.position = Vector2(c4.x + hs.lx, wy - 26)
		hlbl.add_theme_font_size_override("font_size", 11)
		hlbl.add_theme_color_override("font_color", Color(0.72, 0.82, 1.00, 0.82))
		$Districts.add_child(hlbl)

	# ── Вертикальные улицы с тротуарами ────────────────────────────────────
	var v_data: Array = [
		{"x":-520.0,"name":"ул. Корпоративная","ly":-1130.0,"hw":30.0,"sw":10.0},
		{"x": 380.0,"name":"ул. Биржевая",      "ly":-1130.0,"hw":28.0,"sw":10.0},
	]
	for vs in v_data:
		var wx: float = c4.x + vs.x
		var hw2: float = vs.hw; var sw2: float = vs.sw
		var vw1 := ColorRect.new(); vw1.color = side_col
		vw1.offset_left = wx - hw2 - sw2; vw1.offset_right = wx - hw2
		vw1.offset_top = c4.y - W; vw1.offset_bottom = c4.y + W
		$Districts.add_child(vw1)
		var vw2 := ColorRect.new(); vw2.color = side_col
		vw2.offset_left = wx + hw2; vw2.offset_right = wx + hw2 + sw2
		vw2.offset_top = c4.y - W; vw2.offset_bottom = c4.y + W
		$Districts.add_child(vw2)
		var vroad := _make_road_visual(road_col)
		vroad.offset_left = wx - hw2; vroad.offset_right = wx + hw2
		vroad.offset_top = c4.y - W; vroad.offset_bottom = c4.y + W
		$Districts.add_child(vroad)
		_mark_road_rect(vroad)
		var vlbl := Label.new(); vlbl.text = vs.name
		vlbl.position = Vector2(wx + hw2 + sw2 + 4, c4.y + vs.ly)
		vlbl.add_theme_font_size_override("font_size", 11)
		vlbl.add_theme_color_override("font_color", Color(0.72, 0.82, 1.00, 0.82))
		$Districts.add_child(vlbl)

	# ── Пешеходные переходы ──────────────────────────────────────────────────
	var ipts: Array = [Vector2(-520,-390),Vector2(380,-390),Vector2(-520,215),Vector2(380,215)]
	for ip in ipts:
		for si in 8:
			var cb := ColorRect.new(); cb.color = Color(0.94,0.94,0.91,0.72)
			cb.offset_left = c4.x+ip.x+35.0+si*11.5; cb.offset_right = c4.x+ip.x+41.0+si*11.5
			cb.offset_top = c4.y+ip.y-42.0; cb.offset_bottom = c4.y+ip.y+42.0
			$Districts.add_child(cb)
		for sj in 7:
			var cb2 := ColorRect.new(); cb2.color = Color(0.94,0.94,0.91,0.72)
			cb2.offset_left = c4.x+ip.x-30.0; cb2.offset_right = c4.x+ip.x+30.0
			cb2.offset_top = c4.y+ip.y+46.0+sj*11.5; cb2.offset_bottom = c4.y+ip.y+52.0+sj*11.5
			$Districts.add_child(cb2)

	# ── Фонари — внутренняя функция ─────────────────────────────────────────
	var _lamps_h = func(xs: Array, ly_off: float, ax: bool) -> void:
		for lv in xs:
			var lpos: Vector2 = Vector2(c4.x + (lv if ax else ly_off), c4.y + (ly_off if ax else lv))
			var pp := ColorRect.new(); pp.size = Vector2(4,30); pp.position = Vector2(lpos.x-2, lpos.y-34); pp.color = lamp_pole; $Districts.add_child(pp)
			var aa := ColorRect.new(); aa.size = Vector2(14,3); aa.position = Vector2(lpos.x-14, lpos.y-34); aa.color = lamp_pole; $Districts.add_child(aa)
			var gg := ColorRect.new(); gg.size = Vector2(24,16); gg.position = Vector2(lpos.x-22, lpos.y-50); gg.color = lamp_glow; $Districts.add_child(gg)
			var dd2 := ColorRect.new(); dd2.size = Vector2(10,6); dd2.position = Vector2(lpos.x-14, lpos.y-46); dd2.color = lamp_dot; $Districts.add_child(dd2)
	_lamps_h.call([-1050,-840,-620,-380,-140,90,330,580,800,1040], -440.0, true)
	_lamps_h.call([-1050,-820,-560,-290,50,310,590,840],            258.0, true)

	# ── Вертикальные фонари вдоль боковых улиц ──────────────────────────────
	var vert_ys: Array = [-1050,-820,-580,-300,-80,180,450,680,900]
	for ly_v in vert_ys:
		for vx_off in [-556.0, 414.0]:
			var vlx: float = c4.x + vx_off
			var vly: float = c4.y + ly_v
			var vp := ColorRect.new(); vp.size = Vector2(4,30); vp.position = Vector2(vlx+2, vly-2); vp.color = lamp_pole; $Districts.add_child(vp)
			var va := ColorRect.new(); va.size = Vector2(3,12); va.position = Vector2(vlx+2, vly-14); va.color = lamp_pole; $Districts.add_child(va)
			var vg := ColorRect.new(); vg.size = Vector2(16,22); vg.position = Vector2(vlx-12, vly-26); vg.color = lamp_glow; $Districts.add_child(vg)
			var vd := ColorRect.new(); vd.size = Vector2(6,9); vd.position = Vector2(vlx-3, vly-22); vd.color = lamp_dot; $Districts.add_child(vd)

	# ── Luxury-машины вдоль пр. Финансового ────────────────────────────────
	var car_pool4: Array = [TEX_CAR_MUSCLE,TEX_CAR_SEDAN,TEX_CAR_MUSCLE,TEX_CAR_MINI]
	var pxs_n: Array = [-900,-720,-540,-310,-80,160,420,650,880]
	for i in pxs_n.size():
		var sp := Sprite2D.new(); sp.texture = car_pool4[i % car_pool4.size()]
		sp.rotation_degrees = 0.0; sp.scale = Vector2(0.60,0.60)
		sp.position = Vector2(c4.x + pxs_n[i], c4.y - 441); $Districts.add_child(sp)
	var pxs_s: Array = [-850,-620,-350,-100,150,400,640,860]
	for i2 in pxs_s.size():
		var sp2 := Sprite2D.new(); sp2.texture = car_pool4[(i2+1) % car_pool4.size()]
		sp2.rotation_degrees = 180.0; sp2.scale = Vector2(0.58,0.58)
		sp2.position = Vector2(c4.x + pxs_s[i2], c4.y - 340); $Districts.add_child(sp2)

	# ── Машины вдоль Делового бульвара ──────────────────────────────────────
	var pxs_b_n: Array = [-880,-680,-460,-240,-10,220,450,680,900]
	for i3 in pxs_b_n.size():
		var sp3 := Sprite2D.new(); sp3.texture = car_pool4[i3 % car_pool4.size()]
		sp3.rotation_degrees = 0.0; sp3.scale = Vector2(0.58,0.58)
		sp3.position = Vector2(c4.x + pxs_b_n[i3], c4.y + 165); $Districts.add_child(sp3)
	var pxs_b_s: Array = [-820,-580,-340,-90,160,400,640,860]
	for i4 in pxs_b_s.size():
		var sp4 := Sprite2D.new(); sp4.texture = car_pool4[(i4+2) % car_pool4.size()]
		sp4.rotation_degrees = 180.0; sp4.scale = Vector2(0.56,0.56)
		sp4.position = Vector2(c4.x + pxs_b_s[i4], c4.y + 264); $Districts.add_child(sp4)

# ─── Припаркованные машины вдоль улиц Зоны 0 ────────────────────────────────
func _spawn_zone0_parked_cars() -> void:
	var c0: Vector2 = _zone_center(0)
	var car_pool: Array = [TEX_CAR_SEDAN, TEX_CAR_MINI, TEX_CAR_MUSCLE,
						   TEX_CAR_SEDAN, TEX_CAR_MINI]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	# Машины вдоль ул.Рассветной (y≈-660), паркуются с севера (y≈-700)
	var park_y_north: float = c0.y - 700.0
	var xs_chkalova: Array = [-1050, -850, -700, -500, -320, -100, 100, 320, 550, 720]
	for i in xs_chkalova.size():
		var sp := Sprite2D.new()
		sp.texture = car_pool[i % car_pool.size()]
		sp.rotation_degrees = 0.0
		sp.scale = Vector2(0.62, 0.62)
		sp.position = Vector2(c0.x + xs_chkalova[i], park_y_north)
		$Districts.add_child(sp)

	# Машины вдоль ул.Мирной (y≈+80), паркуются с юга (y≈+130)
	var park_y_south: float = c0.y + 130.0
	var xs_narodnaya: Array = [-1000, -780, -550, -280, 60, 300, 580, 800]
	for i in xs_narodnaya.size():
		var sp := Sprite2D.new()
		sp.texture = car_pool[(i + 2) % car_pool.size()]
		sp.rotation_degrees = 180.0
		sp.scale = Vector2(0.62, 0.62)
		sp.position = Vector2(c0.x + xs_narodnaya[i], park_y_south)
		$Districts.add_child(sp)

	# Машины у гаражей (x≈700-1010, y≈500)
	var garage_cars: Array = [
		Vector2(720, 510), Vector2(790, 510), Vector2(860, 510), Vector2(930, 510)
	]
	for i in garage_cars.size():
		var sp := Sprite2D.new()
		sp.texture = car_pool[i % car_pool.size()]
		sp.rotation_degrees = 90.0
		sp.scale = Vector2(0.55, 0.55)
		sp.position = c0 + garage_cars[i]
		$Districts.add_child(sp)

# ─── Внутренние улицы Зоны 2 — Спальный район «Северный» ───────────────────
func _spawn_zone2_streets() -> void:
	var c2: Vector2 = _zone_center(2)
	var road_col  := Color(0.16, 0.16, 0.18, 0.95)
	var side_col  := Color(0.22, 0.22, 0.26, 0.82)
	var lbl_col   := Color(0.85, 0.85, 0.92, 0.88)
	var lamp_col  := Color(1.00, 0.95, 0.80, 0.90)
	var xwalk_col := Color(0.90, 0.90, 0.90, 0.55)

	var add := func(parent: Node, col: Color, x: float, y: float, w: float, h: float) -> ColorRect:
		var r := ColorRect.new()
		r.color = col
		r.size = Vector2(w, h)
		r.position = c2 + Vector2(x - w * 0.5, y - h * 0.5)
		parent.add_child(r)
		return r

	var add_road := func(parent: Node, x: float, y: float, w: float, h: float) -> Control:
		var r := _make_road_visual(road_col)
		r.size = Vector2(w, h)
		r.position = c2 + Vector2(x - w * 0.5, y - h * 0.5)
		parent.add_child(r)
		return r

	# ══ БУЛ. МОЛОДЁЖНЫЙ — горизонталь y≈-620 ══
	_mark_road_from_posrect(add_road.call($Districts,   0.0, -620.0, 1900.0, 46.0))
	add.call($Districts, side_col, -950.0, -620.0, 1900.0,  5.0)
	add.call($Districts, side_col, -950.0, -597.0, 1900.0,  5.0)
	for xi in [-840, -560, -280, 0, 280, 560, 840]:
		add.call($Districts, lamp_col, float(xi), -645.0, 6.0, 22.0)
		add.call($Districts, lamp_col, float(xi), -597.0, 6.0, 22.0)
	var lbl_bul := Label.new()
	lbl_bul.text = "бул. Молодёжный"
	lbl_bul.add_theme_color_override("font_color", lbl_col)
	lbl_bul.add_theme_font_size_override("font_size", 11)
	lbl_bul.position = c2 + Vector2(-75.0, -638.0)
	$Districts.add_child(lbl_bul)
	for si in range(5):
		add.call($Districts, xwalk_col, -700.0, -620.0 + float(si) * 8.0 - 18.0, 14.0, 4.0)
		add.call($Districts, xwalk_col,  700.0, -620.0 + float(si) * 8.0 - 18.0, 14.0, 4.0)

	# ══ УЛ. ПАРКОВАЯ — горизонталь y≈+130 ══
	_mark_road_from_posrect(add_road.call($Districts,   0.0, 130.0, 1900.0, 42.0))
	add.call($Districts, side_col, -950.0, 130.0, 1900.0,  4.0)
	add.call($Districts, side_col, -950.0, 151.0, 1900.0,  4.0)
	for xi in [-840, -560, -280, 0, 280, 560, 840]:
		add.call($Districts, lamp_col, float(xi), 107.0, 6.0, 20.0)
		add.call($Districts, lamp_col, float(xi), 153.0, 6.0, 20.0)
	var lbl_park := Label.new()
	lbl_park.text = "ул. Парковая"
	lbl_park.add_theme_color_override("font_color", lbl_col)
	lbl_park.add_theme_font_size_override("font_size", 11)
	lbl_park.position = c2 + Vector2(-55.0, 113.0)
	$Districts.add_child(lbl_park)
	for si in range(5):
		add.call($Districts, xwalk_col, -700.0, 130.0 + float(si) * 8.0 - 18.0, 14.0, 4.0)
		add.call($Districts, xwalk_col,  700.0, 130.0 + float(si) * 8.0 - 18.0, 14.0, 4.0)

	# ══ ПР. СЕВЕРНЫЙ — вертикаль x≈-720 ══
	_mark_road_from_posrect(add_road.call($Districts, -720.0,   0.0, 42.0, 1900.0))
	add.call($Districts, side_col, -720.0, -950.0,  4.0, 1900.0)
	add.call($Districts, side_col, -699.0, -950.0,  4.0, 1900.0)
	for yi in [-840, -560, -280, 0, 280, 560, 840]:
		add.call($Districts, lamp_col, -743.0, float(yi), 20.0, 6.0)
		add.call($Districts, lamp_col, -697.0, float(yi), 20.0, 6.0)
	var lbl_sev := Label.new()
	lbl_sev.text = "пр. Северный"
	lbl_sev.add_theme_color_override("font_color", lbl_col)
	lbl_sev.add_theme_font_size_override("font_size", 11)
	lbl_sev.rotation_degrees = -90.0
	lbl_sev.position = c2 + Vector2(-728.0, 60.0)
	$Districts.add_child(lbl_sev)
	for si in range(5):
		add.call($Districts, xwalk_col, -720.0 + float(si) * 8.0 - 18.0, -550.0, 4.0, 14.0)
		add.call($Districts, xwalk_col, -720.0 + float(si) * 8.0 - 18.0,  200.0, 4.0, 14.0)

	# ══ УЛ. ШКОЛЬНАЯ — вертикаль x≈+320 ══
	_mark_road_from_posrect(add_road.call($Districts,  320.0,   0.0, 38.0, 1900.0))
	add.call($Districts, side_col,  320.0, -950.0,  4.0, 1900.0)
	add.call($Districts, side_col,  339.0, -950.0,  4.0, 1900.0)
	for yi in [-840, -560, -280, 0, 280, 560, 840]:
		add.call($Districts, lamp_col,  297.0, float(yi), 20.0, 6.0)
		add.call($Districts, lamp_col,  341.0, float(yi), 20.0, 6.0)
	var lbl_sch := Label.new()
	lbl_sch.text = "ул. Школьная"
	lbl_sch.add_theme_color_override("font_color", lbl_col)
	lbl_sch.add_theme_font_size_override("font_size", 11)
	lbl_sch.rotation_degrees = -90.0
	lbl_sch.position = c2 + Vector2(313.0, 58.0)
	$Districts.add_child(lbl_sch)
	for si in range(5):
		add.call($Districts, xwalk_col,  320.0 + float(si) * 8.0 - 18.0, -550.0, 4.0, 14.0)
		add.call($Districts, xwalk_col,  320.0 + float(si) * 8.0 - 18.0,  200.0, 4.0, 14.0)

# ─── Улицы Зоны 3 — Средний класс ───────────────────────────────────────────
func _spawn_zone3_streets() -> void:
	var c3: Vector2 = _zone_center(3)
	var road_col  := Color(0.15, 0.15, 0.17, 0.96)
	var side_col  := Color(0.22, 0.22, 0.26, 0.85)
	var lamp_col_pole := Color(0.32, 0.32, 0.38)
	var lamp_col_glow := Color(0.80, 0.92, 1.00, 0.28)
	var lamp_col_dot  := Color(0.88, 0.96, 1.00, 0.90)
	var W: float = 1150.0

	var h_streets: Array = [
		{"y": -645.0, "name": "бул. Центральный", "label_x": -1100.0, "hw": 38.0},
		{"y":  100.0, "name": "ул. Советская",    "label_x": -1100.0, "hw": 32.0},
	]
	for hs in h_streets:
		var wy: float = c3.y + hs.y
		var hw: float = hs.hw
		var sw1 := ColorRect.new(); sw1.color = side_col
		sw1.offset_left = c3.x - W; sw1.offset_right = c3.x + W
		sw1.offset_top = wy - hw - 12.0; sw1.offset_bottom = wy - hw
		$Districts.add_child(sw1)
		var sw2 := ColorRect.new(); sw2.color = side_col
		sw2.offset_left = c3.x - W; sw2.offset_right = c3.x + W
		sw2.offset_top = wy + hw; sw2.offset_bottom = wy + hw + 12.0
		$Districts.add_child(sw2)
		var hroad := _make_road_visual(road_col)
		hroad.offset_left = c3.x - W; hroad.offset_right = c3.x + W
		hroad.offset_top = wy - hw; hroad.offset_bottom = wy + hw
		$Districts.add_child(hroad)
		_mark_road_rect(hroad)
		var hlbl := Label.new(); hlbl.text = hs.name
		hlbl.position = Vector2(c3.x + hs.label_x, wy - 28)
		hlbl.add_theme_font_size_override("font_size", 11)
		hlbl.add_theme_color_override("font_color", Color(0.78, 0.82, 0.62, 0.82))
		$Districts.add_child(hlbl)

	var v_streets: Array = [
		{"x": -337.0, "name": "пр. Университетский", "label_y": -1100.0, "hw": 30.0},
		{"x":  610.0, "name": "ул. Торговая",         "label_y": -1100.0, "hw": 28.0},
	]
	for vs in v_streets:
		var wx: float = c3.x + vs.x
		var hw: float = vs.hw
		var vw1 := ColorRect.new(); vw1.color = side_col
		vw1.offset_left = wx - hw - 12.0; vw1.offset_right = wx - hw
		vw1.offset_top = c3.y - W; vw1.offset_bottom = c3.y + W
		$Districts.add_child(vw1)
		var vw2 := ColorRect.new(); vw2.color = side_col
		vw2.offset_left = wx + hw; vw2.offset_right = wx + hw + 12.0
		vw2.offset_top = c3.y - W; vw2.offset_bottom = c3.y + W
		$Districts.add_child(vw2)
		var vroad := _make_road_visual(road_col)
		vroad.offset_left = wx - hw; vroad.offset_right = wx + hw
		vroad.offset_top = c3.y - W; vroad.offset_bottom = c3.y + W
		$Districts.add_child(vroad)
		_mark_road_rect(vroad)
		var vlbl := Label.new(); vlbl.text = vs.name
		vlbl.position = Vector2(wx + 34, c3.y + vs.label_y)
		vlbl.add_theme_font_size_override("font_size", 11)
		vlbl.add_theme_color_override("font_color", Color(0.78, 0.82, 0.62, 0.82))
		$Districts.add_child(vlbl)

	var intersections: Array = [
		Vector2(-337.0, -645.0), Vector2(610.0, -645.0),
		Vector2(-337.0,  100.0), Vector2(610.0,  100.0),
	]
	for ip in intersections:
		var zc := Color(0.96, 0.96, 0.94, 0.70)
		# Восток (→)
		for si in 7:
			var cb := ColorRect.new(); cb.color = zc
			cb.offset_left   = c3.x + ip.x + 33.0 + si * 11.0
			cb.offset_right  = c3.x + ip.x + 38.0 + si * 11.0
			cb.offset_top    = c3.y + ip.y - 38.0
			cb.offset_bottom = c3.y + ip.y + 38.0
			$Districts.add_child(cb)
		# Запад (←)
		for si in 7:
			var cb := ColorRect.new(); cb.color = zc
			cb.offset_left   = c3.x + ip.x - 38.0 - si * 11.0
			cb.offset_right  = c3.x + ip.x - 33.0 - si * 11.0
			cb.offset_top    = c3.y + ip.y - 38.0
			cb.offset_bottom = c3.y + ip.y + 38.0
			$Districts.add_child(cb)
		# Юг (↓)
		for sj in 6:
			var cb2 := ColorRect.new(); cb2.color = zc
			cb2.offset_left   = c3.x + ip.x - 30.0
			cb2.offset_right  = c3.x + ip.x + 30.0
			cb2.offset_top    = c3.y + ip.y + 42.0 + sj * 11.0
			cb2.offset_bottom = c3.y + ip.y + 47.0 + sj * 11.0
			$Districts.add_child(cb2)
		# Север (↑)
		for sj in 6:
			var cb2 := ColorRect.new(); cb2.color = zc
			cb2.offset_left   = c3.x + ip.x - 30.0
			cb2.offset_right  = c3.x + ip.x + 30.0
			cb2.offset_top    = c3.y + ip.y - 47.0 - sj * 11.0
			cb2.offset_bottom = c3.y + ip.y - 42.0 - sj * 11.0
			$Districts.add_child(cb2)

	var lamp_xs_c: Array = [-1050,-840,-620,-380,-120, 80, 330, 580, 800, 1000]
	for lx in lamp_xs_c:
		var ly_c: float = c3.y - 688.0
		var pole_c := ColorRect.new(); pole_c.size = Vector2(4,30)
		pole_c.position = Vector2(c3.x + lx - 2, ly_c - 32); pole_c.color = lamp_col_pole
		$Districts.add_child(pole_c)
		var arm_c := ColorRect.new(); arm_c.size = Vector2(12, 3)
		arm_c.position = Vector2(c3.x + lx - 12, ly_c - 32); arm_c.color = lamp_col_pole
		$Districts.add_child(arm_c)
		var glow_c := ColorRect.new(); glow_c.size = Vector2(22, 14)
		glow_c.position = Vector2(c3.x + lx - 20, ly_c - 46); glow_c.color = lamp_col_glow
		$Districts.add_child(glow_c)
		var dot_c := ColorRect.new(); dot_c.size = Vector2(9, 5)
		dot_c.position = Vector2(c3.x + lx - 13, ly_c - 43); dot_c.color = lamp_col_dot
		$Districts.add_child(dot_c)

	var lamp_xs_s: Array = [-1000,-780,-540,-280, 50, 300, 580, 820]
	for lx2 in lamp_xs_s:
		var ly_s: float = c3.y + 145.0
		var pole_s := ColorRect.new(); pole_s.size = Vector2(4,28)
		pole_s.position = Vector2(c3.x + lx2 - 2, ly_s + 2); pole_s.color = lamp_col_pole
		$Districts.add_child(pole_s)
		var arm_s := ColorRect.new(); arm_s.size = Vector2(12, 3)
		arm_s.position = Vector2(c3.x + lx2 - 12, ly_s + 2); arm_s.color = lamp_col_pole
		$Districts.add_child(arm_s)
		var glow_s := ColorRect.new(); glow_s.size = Vector2(22, 14)
		glow_s.position = Vector2(c3.x + lx2 - 20, ly_s - 12); glow_s.color = lamp_col_glow
		$Districts.add_child(glow_s)
		var dot_s := ColorRect.new(); dot_s.size = Vector2(9, 5)
		dot_s.position = Vector2(c3.x + lx2 - 13, ly_s - 9); dot_s.color = lamp_col_dot
		$Districts.add_child(dot_s)

	var lamp_ys_u: Array = [-1050,-820,-580,-340,-90, 160, 420, 680, 920]
	for ly3 in lamp_ys_u:
		var lx3: float = c3.x - 300.0
		var pole_u := ColorRect.new(); pole_u.size = Vector2(4,28)
		pole_u.position = Vector2(lx3 + 2, c3.y + ly3 - 2); pole_u.color = lamp_col_pole
		$Districts.add_child(pole_u)
		var arm_u := ColorRect.new(); arm_u.size = Vector2(3,12)
		arm_u.position = Vector2(lx3 + 2, c3.y + ly3 - 14); arm_u.color = lamp_col_pole
		$Districts.add_child(arm_u)
		var glow_u := ColorRect.new(); glow_u.size = Vector2(14,22)
		glow_u.position = Vector2(lx3 - 10, c3.y + ly3 - 26); glow_u.color = lamp_col_glow
		$Districts.add_child(glow_u)
		var dot_u := ColorRect.new(); dot_u.size = Vector2(5,9)
		dot_u.position = Vector2(lx3 - 3, c3.y + ly3 - 22); dot_u.color = lamp_col_dot
		$Districts.add_child(dot_u)

	var lamp_ys_t: Array = [-1050,-820,-580,-340,-90, 160, 420, 680, 920]
	for ly4 in lamp_ys_t:
		var lx4: float = c3.x + 648.0
		var pole_t := ColorRect.new(); pole_t.size = Vector2(4,28)
		pole_t.position = Vector2(lx4 + 2, c3.y + ly4 - 2); pole_t.color = lamp_col_pole
		$Districts.add_child(pole_t)
		var arm_t := ColorRect.new(); arm_t.size = Vector2(3,12)
		arm_t.position = Vector2(lx4 + 2, c3.y + ly4 - 14); arm_t.color = lamp_col_pole
		$Districts.add_child(arm_t)
		var glow_t := ColorRect.new(); glow_t.size = Vector2(14,22)
		glow_t.position = Vector2(lx4 - 10, c3.y + ly4 - 26); glow_t.color = lamp_col_glow
		$Districts.add_child(glow_t)
		var dot_t := ColorRect.new(); dot_t.size = Vector2(5,9)
		dot_t.position = Vector2(lx4 - 3, c3.y + ly4 - 22); dot_t.color = lamp_col_dot
		$Districts.add_child(dot_t)

	var car_pool3: Array = [TEX_CAR_SEDAN, TEX_CAR_MUSCLE, TEX_CAR_SEDAN, TEX_CAR_MINI, TEX_CAR_MUSCLE]
	var park_y3: float = c3.y - 692.0
	var xs_c3: Array = [-1000,-820,-630,-420,-180, 50, 310, 560, 780, 960]
	for i3 in xs_c3.size():
		var sp3 := Sprite2D.new()
		sp3.texture = car_pool3[i3 % car_pool3.size()]
		sp3.rotation_degrees = 0.0; sp3.scale = Vector2(0.64, 0.64)
		sp3.position = Vector2(c3.x + xs_c3[i3], park_y3)
		$Districts.add_child(sp3)

	var park_y3s: float = c3.y + 148.0
	var xs_s3: Array = [-970,-760,-520,-250, 80, 350, 620, 860]
	for i4 in xs_s3.size():
		var sp4 := Sprite2D.new()
		sp4.texture = car_pool3[(i4 + 1) % car_pool3.size()]
		sp4.rotation_degrees = 180.0; sp4.scale = Vector2(0.62, 0.62)
		sp4.position = Vector2(c3.x + xs_s3[i4], park_y3s)
		$Districts.add_child(sp4)

# ─── Припаркованные машины у главных дорог всех зон (зоны 1-8) ──────────────
func _spawn_all_zone_parked_cars() -> void:
	var all_cars: Array = [TEX_CAR_SEDAN, TEX_CAR_MINI, TEX_CAR_MUSCLE,
						   TEX_CAR_SEDAN, TEX_CAR_MINI]
	var luxury_cars: Array = [TEX_CAR_MUSCLE, TEX_CAR_SEDAN, TEX_CAR_MUSCLE]
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	# Для зон 1-8: ставим машины вдоль внутренних дорог зон
	# Каждая зона имеет центр _zone_center(z), машины вдоль y=±700 и x=±700
	for z in range(1, 9):
		var center: Vector2 = _zone_center(z)
		var pool: Array = luxury_cars if z >= 5 else all_cars
		# Горизонтальный ряд сверху (y ≈ -750)
		var count_h: int = 5 + z
		for i in count_h:
			var sp := Sprite2D.new()
			sp.texture = pool[(i + z) % pool.size()]
			sp.rotation_degrees = 0.0
			sp.scale = Vector2(0.58, 0.58)
			sp.position = Vector2(center.x - 800 + i * 280, center.y - 760)
			$Districts.add_child(sp)
		# Горизонтальный ряд снизу (y ≈ +750)
		for i in count_h:
			var sp := Sprite2D.new()
			sp.texture = pool[(i + z + 2) % pool.size()]
			sp.rotation_degrees = 180.0
			sp.scale = Vector2(0.58, 0.58)
			sp.position = Vector2(center.x - 700 + i * 280, center.y + 760)
			$Districts.add_child(sp)

# ─── Движущийся трафик на главных дорогах ────────────────────────────────────
func _spawn_road_traffic() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 131
	var car_pool: Array = [TEX_CAR_SEDAN, TEX_CAR_MINI, TEX_CAR_MUSCLE]
	var road_half: float = MAP_HALF  # 3750

	# Горизонтальные дороги (y = -2500, 0, +2500)
	for ry: float in [-2500.0, 0.0, 2500.0]:
		for lane_dir: int in [1, -1]:
			var lane_y: float = ry + lane_dir * -20.0
			var cars_per_lane: int = 6
			for i in cars_per_lane:
				var sp := Sprite2D.new()
				sp.texture = car_pool[rng.randi() % car_pool.size()]
				sp.scale = Vector2(0.52, 0.52)
				sp.rotation_degrees = 0.0 if lane_dir > 0 else 180.0
				var start_x: float = -road_half + i * (road_half * 2.0 / cars_per_lane) + rng.randf_range(-120, 120)
				sp.position = Vector2(start_x, lane_y)
				$Districts.add_child(sp)
				var spd: float = rng.randf_range(190, 340) * lane_dir
				_traffic_cars.append({"node": sp, "speed": spd, "axis": "x",
					"min": -road_half - 200, "max": road_half + 200})

	# Вертикальные дороги (x = -2500, 0, +2500)
	for rx: float in [-2500.0, 0.0, 2500.0]:
		for lane_dir: int in [1, -1]:
			var lane_x: float = rx + lane_dir * 20.0
			var cars_per_lane: int = 6
			for i in cars_per_lane:
				var sp := Sprite2D.new()
				sp.texture = car_pool[rng.randi() % car_pool.size()]
				sp.scale = Vector2(0.52, 0.52)
				sp.rotation_degrees = 90.0 if lane_dir > 0 else -90.0
				var start_y: float = -road_half + i * (road_half * 2.0 / cars_per_lane) + rng.randf_range(-120, 120)
				sp.position = Vector2(lane_x, start_y)
				$Districts.add_child(sp)
				var spd: float = rng.randf_range(190, 340) * lane_dir
				_traffic_cars.append({"node": sp, "speed": spd, "axis": "y",
					"min": -road_half - 200, "max": road_half + 200})

# ─── Дороги на всей карте ─────────────────────────────────────────────────────
func _spawn_map_roads() -> void:
	var road_col  := Color(0.18, 0.18, 0.18, 0.92)

	# 3 горизонтальных дороги (y = -2500, 0, +2500)
	for ri in 3:
		var ry: float = (ri - 1) * ZONE_SIZE
		var road := _make_road_visual(road_col)
		road.offset_left   = -MAP_HALF
		road.offset_right  =  MAP_HALF
		road.offset_top    = ry - 38.0
		road.offset_bottom = ry + 38.0
		$Districts.add_child(road)
		_mark_road_rect(road)

	# 3 вертикальных дороги (x = -2500, 0, +2500)
	for ci2 in 3:
		var rx: float = (ci2 - 1) * ZONE_SIZE
		var road := _make_road_visual(road_col)
		road.offset_left   = rx - 38.0
		road.offset_right  = rx + 38.0
		road.offset_top    = -MAP_HALF
		road.offset_bottom =  MAP_HALF
		$Districts.add_child(road)
		_mark_road_rect(road)

# ─── Фоны всех 9 зон ─────────────────────────────────────────────────────────
func _spawn_all_zone_backgrounds(_zm: Node) -> void:
	var hw: float = ZONE_SIZE / 2.0

	for z in 9:
		var center: Vector2 = _zone_center(z)

		# ── Сплошная заливка земли без швов (вместо мозаики из плиток) ──────
		var ground := ColorRect.new()
		var base_col: Color = GROUND_BASE_COLORS[z]
		ground.color = base_col
		ground.offset_left   = center.x - hw
		ground.offset_right  = center.x + hw
		ground.offset_top    = center.y - hw
		ground.offset_bottom = center.y + hw
		$Districts.add_child(ground)

		# Органический шум (случайные мягкие пятна светлее/темнее) — убирает "пустой" плоский вид
		var grng := RandomNumberGenerator.new()
		grng.seed = z * 9901 + 17
		var blotches: int = int(ZONE_SIZE * ZONE_SIZE / 9000.0)
		for _i in blotches:
			var bx: float = center.x - hw + grng.randf() * ZONE_SIZE
			var by: float = center.y - hw + grng.randf() * ZONE_SIZE
			var bsz: float = grng.randf_range(40, 110)
			var blot := ColorRect.new()
			blot.size = Vector2(bsz, bsz)
			blot.position = Vector2(bx - bsz * 0.5, by - bsz * 0.5)
			var shade: float = grng.randf_range(-0.05, 0.06)
			blot.color = Color(clampf(base_col.r + shade, 0, 1), clampf(base_col.g + shade, 0, 1), clampf(base_col.b + shade, 0, 1), grng.randf_range(0.18, 0.40))
			blot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			$Districts.add_child(blot)

		# Атмосферный оверлей зоны
		var meta: Dictionary = ZoneManager.ZONE_META[z]
		var ov := ColorRect.new()
		ov.color = Color(meta.bg.r, meta.bg.g, meta.bg.b, 0.22)
		ov.offset_left   = center.x - hw
		ov.offset_right  = center.x + hw
		ov.offset_top    = center.y - hw
		ov.offset_bottom = center.y + hw
		$Districts.add_child(ov)

		# Название зоны (полупрозрачно)
		var lbl := Label.new()
		lbl.text = meta.icon + "  " + meta.name
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 20)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.18))
		lbl.position = center + Vector2(-300, -hw + 40)
		lbl.size = Vector2(600, 40)
		$Districts.add_child(lbl)

		# Номер зоны
		var num := Label.new()
		num.text = "Зона %d / 9" % (z + 1)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.add_theme_font_size_override("font_size", 13)
		num.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.25))
		num.position = center + Vector2(-200, -hw + 70)
		num.size = Vector2(400, 24)
		$Districts.add_child(num)

		if z >= 5:
			_spawn_zone_particles(z, center)

# ─── Динамическое освещение день/ночь ────────────────────────────────────────
# CanvasModulate красит весь 2D-рендер сразу (земля, дороги, здания, NPC) —
# без него игра выглядит одинаково плоско в 10 утра и в полночь.
func _setup_day_night() -> void:
	_canvas_modulate = CanvasModulate.new()
	add_child(_canvas_modulate)
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		gm.time_changed.connect(_on_world_time_changed)
		if gm.has_signal("season_changed"):
			gm.season_changed.connect(func(_i): _on_world_time_changed(gm.current_hour, gm.current_minute))
		_on_world_time_changed(gm.current_hour, gm.current_minute)
	else:
		_canvas_modulate.color = Color(1.0, 1.0, 1.0)

func _on_world_time_changed(h: int, m: int) -> void:
	if _canvas_modulate:
		var col: Color = _daynight_color(h, m)
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm and gm.has_method("get_season"):
			var tint: Color = gm.get_season().get("tint", Color(1, 1, 1))
			col = Color(col.r * tint.r, col.g * tint.g, col.b * tint.b)
		_canvas_modulate.color = col

# Ключевые точки цикла (час -> цвет); между ними плавная интерполяция
const DAYNIGHT_KEYS: Array = [
	[0.0,  Color(0.42, 0.46, 0.70)],   # глубокая ночь
	[5.0,  Color(0.42, 0.46, 0.70)],
	[7.0,  Color(0.95, 0.72, 0.58)],   # рассвет — тёплый
	[9.0,  Color(1.06, 1.04, 0.98)],   # яркий день
	[17.0, Color(1.06, 1.04, 0.98)],
	[19.5, Color(0.92, 0.58, 0.48)],   # закат — оранжевый
	[21.0, Color(0.42, 0.46, 0.70)],   # ночь
	[24.0, Color(0.42, 0.46, 0.70)],
]

func _daynight_color(hour: int, minute: int) -> Color:
	var t: float = float(hour) + float(minute) / 60.0
	for i in range(DAYNIGHT_KEYS.size() - 1):
		var a: Array = DAYNIGHT_KEYS[i]
		var b: Array = DAYNIGHT_KEYS[i + 1]
		if t >= a[0] and t <= b[0]:
			var f: float = 0.0 if b[0] == a[0] else (t - a[0]) / (b[0] - a[0])
			return (a[1] as Color).lerp(b[1] as Color, f)
	return DAYNIGHT_KEYS[0][1]

# ─── Атмосферные частицы для элитных зон (5+) ───────────────────────────────
func _spawn_zone_particles(zone: int, center: Vector2) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = zone * 13337
	var palette: Array
	if zone <= 6:
		palette = [Color(1.0, 0.88, 0.28, 0.75), Color(0.95, 0.75, 0.22, 0.60), Color(0.82, 0.68, 1.0, 0.55)]
	else:
		palette = [Color(0.72, 0.88, 1.0, 0.70), Color(0.88, 0.78, 1.0, 0.65), Color(0.60, 1.0, 0.90, 0.60)]
	var count: int = 18 + zone * 4
	for i in count:
		var sp := ColorRect.new()
		var sz: float = rng.randf_range(2.0, 5.5)
		sp.size = Vector2(sz, sz)
		var col: Color = palette[rng.randi() % palette.size()]
		sp.color = col
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sx: float = center.x + rng.randf_range(-1050, 1050)
		var sy: float = center.y + rng.randf_range(-1050, 1050)
		sp.position = Vector2(sx, sy)
		$Districts.add_child(sp)
		var float_dist: float = rng.randf_range(18, 48)
		var period: float = rng.randf_range(3.5, 8.0)
		var delay: float = rng.randf_range(0.0, period)
		var tw := sp.create_tween()
		tw.set_loops()
		tw.tween_callback(func(): sp.position = Vector2(sx, sy); sp.modulate.a = 0.0)
		tw.tween_interval(delay)
		tw.tween_property(sp, "modulate:a", 1.0, 0.6)
		tw.tween_property(sp, "position:y", sy - float_dist, period * 0.7).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(sp, "modulate:a", 0.0, period * 0.3)

# ─── Все здания (все 9 зон) ───────────────────────────────────────────────────
# Авторынки по зонам: название, цвет и иконка прогрессируют вместе с зоной
const _TRANSPORT_SHOPS: Array = [
	{"zone":0, "name":"🛴 Прокат самокатов", "color":Color(0.30,0.45,0.30), "pos":Vector2( 200,-700)},
	{"zone":1, "name":"🚲 Велосипеды",       "color":Color(0.30,0.45,0.35), "pos":Vector2(-200,-700)},
	{"zone":2, "name":"🚗 Авторынок",        "color":Color(0.35,0.35,0.50), "pos":Vector2( 200,-700)},
	{"zone":3, "name":"🚗 Автосалон",        "color":Color(0.30,0.38,0.55), "pos":Vector2(-200,-700), "tex":"res://assets/textures/Avtosalon.png"},
	{"zone":4, "name":"🚙 Иномарки",         "color":Color(0.22,0.32,0.58), "pos":Vector2( 200,-700)},
	{"zone":5, "name":"🚙 Элит-Авто",        "color":Color(0.20,0.28,0.55), "pos":Vector2(-200,-700)},
	{"zone":6, "name":"🏎 Суперкары",        "color":Color(0.38,0.22,0.45), "pos":Vector2( 200,-700)},
	{"zone":7, "name":"🏎 VIP Моторс",       "color":Color(0.35,0.25,0.48), "pos":Vector2(-200,-700)},
	{"zone":8, "name":"✈ Авиасалон",         "color":Color(0.18,0.22,0.42), "pos":Vector2( 200,-700)},
]

func _spawn_all_buildings() -> void:
	for z in ZONE_BUILDINGS.size():
		var center: Vector2 = _zone_center(z)
		for d in ZONE_BUILDINGS[z]:
			var bd: Dictionary = d.duplicate()
			bd["pos"] = center + d.pos
			bd["zone"] = z
			_spawn_building(bd)
		# Авторынок в каждой зоне
		var ts_data: Dictionary = _TRANSPORT_SHOPS[z]
		var ts_col = ts_data.color if ts_data.color is Color else Color(0.30,0.28,0.45)
		var ts_bd: Dictionary = {
			"name":  ts_data.name,
			"action":"Купить транспорт",
			"reward":0, "cd":999,
			"pos":   center + ts_data.pos,
			"color": ts_col,
			"transport_shop": true,
			"zone": z
		}
		if ts_data.has("tex"):
			ts_bd["tex"] = ts_data.tex
		_spawn_building(ts_bd)
		# Криминальные работы только в зоне 0
		if z == 0:
			var cj_positions := [Vector2(-1100, -400), Vector2(-1000, 300), Vector2(-1150, 100)]
			for pos in cj_positions:
				var cj := Area2D.new()
				cj.set_script(CriminalJobScript)
				cj.position = center + pos
				$Buildings.add_child(cj)

func _spawn_all_npcs() -> void:
	for z in ZONE_NPC.size():
		var center: Vector2 = _zone_center(z)
		for d in ZONE_NPC[z]:
			var nd: Dictionary = d.duplicate()
			nd["pos"] = center + d.pos
			_spawn_npc(nd)

func _spawn_all_deco() -> void:
	for z in DECO_ZONES.size():
		var center: Vector2 = _zone_center(z)
		_spawn_deco_for_zone(z, center)

# ─── Переход зоны (через тур.фирму) ─────────────────────────────────────────
func _setup_zone_lock_overlays(zm: Node) -> void:
	var unlocked: int = zm.max_zone_reached
	for z in 9:
		if z <= unlocked:
			continue
		var center: Vector2 = _zone_center(z)
		var hw: float = ZONE_SIZE / 2.0

		var fog := ColorRect.new()
		fog.offset_left   = center.x - hw
		fog.offset_right  = center.x + hw
		fog.offset_top    = center.y - hw
		fog.offset_bottom = center.y + hw
		fog.color = Color(0.02, 0.02, 0.06, 0.82)
		fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		$Districts.add_child(fog)

		var lock_lbl := Label.new()
		lock_lbl.text = "🔒"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.position = center + Vector2(-40, -72)
		lock_lbl.size = Vector2(80, 72)
		lock_lbl.add_theme_font_size_override("font_size", 48)
		lock_lbl.add_theme_constant_override("outline_size", 4)
		lock_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
		$Districts.add_child(lock_lbl)

		var cond: Dictionary = {}
		if z > 0 and (z - 1) < ZoneManager.ZONE_CONDITIONS.size():
			cond = ZoneManager.ZONE_CONDITIONS[z - 1]

		var req_lbl := Label.new()
		req_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		req_lbl.position = center + Vector2(-220, 12)
		req_lbl.size = Vector2(440, 90)
		req_lbl.add_theme_font_size_override("font_size", 16)
		req_lbl.add_theme_color_override("font_color", Color(0.84, 0.80, 0.60, 0.90))
		req_lbl.add_theme_constant_override("outline_size", 3)
		req_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.82))
		if not cond.is_empty():
			var gm2 := get_node("/root/GameManager")
			var em2 := get_node_or_null("/root/EducationManager")
			var t_name: String = gm2.TITLES[cond.get("title_req", 0)].name
			var e_name: String = ""
			if em2 and cond.has("edu_req"):
				e_name = " + " + em2.LEVELS[cond.edu_req].name
			req_lbl.text = t_name + e_name
		else:
			req_lbl.text = ZoneManager.ZONE_META[z].name
		$Districts.add_child(req_lbl)

		_zone_lock_overlays[z] = [fog, lock_lbl, req_lbl]

func _on_zone_changed(zone_idx: int) -> void:
	var zm: Node = get_node("/root/ZoneManager")
	if zm._travel_teleport:
		teleport_to_zone(zone_idx)
	# Снять туман с разблокированной зоны
	if _zone_lock_overlays.has(zone_idx):
		var nodes: Array = _zone_lock_overlays[zone_idx]
		var tw := create_tween()
		tw.set_parallel(true)
		for n in nodes:
			if is_instance_valid(n):
				tw.tween_property(n, "modulate:a", 0.0, 2.0)
		tw.set_parallel(false)
		tw.tween_callback(func():
			for n in nodes:
				if is_instance_valid(n): n.queue_free()
		)
		_zone_lock_overlays.erase(zone_idx)
	_last_zone = zone_idx

# Публичный метод — телепорт игрока в центр зоны (используется TravelAgencyUI)
func teleport_to_zone(z: int) -> void:
	var player_node = get_node_or_null("Player")
	if player_node:
		player_node.global_position = _zone_center(z) + Vector2(0, 150)
		_player_cached = player_node
		_cull_all()

# ─── Вспомогательные системы (один экземпляр на всю карту) ──────────────────
func _spawn_common_systems() -> void:
	var fs = FoodShopScene.instantiate()
	fs.add_to_group("food_shop"); add_child(fs)

	var np = NewspaperScene.instantiate()
	np.name = "Newspaper"; add_child(np)

	var es = EducationShopScene.instantiate()
	es.add_to_group("education_shop"); add_child(es)

	var ta = TravelAgencyUIScene.instantiate()
	add_child(ta)

	var ts = TransportShopUIScene.instantiate()
	add_child(ts)

	var rs_script := load("res://scripts/RadioShopUI.gd")
	var rs := CanvasLayer.new()
	rs.set_script(rs_script)
	add_child(rs)

# ─── Автобусные остановки ─────────────────────────────────────────────────────
func _spawn_bus_stops() -> void:
	for d in BUS_STOPS:
		var stop := Area2D.new()
		stop.set_script(BusStopScript)
		stop.stop_name = d.name
		stop.position  = d.pos
		add_child(stop)

func _spawn_bus_stop_ui() -> void:
	var ui = BusStopUIScene.instantiate()
	add_child(ui)

# ─── Внешние стены (границы всей карты) ──────────────────────────────────────
func _spawn_outer_walls() -> void:
	var t: float = 80.0
	var walls := [
		[0,        -MAP_HALF - t*0.5, MAP_HALF*2 + t*2, t],
		[0,         MAP_HALF + t*0.5, MAP_HALF*2 + t*2, t],
		[-MAP_HALF - t*0.5, 0, t, MAP_HALF*2 + t*2],
		[ MAP_HALF + t*0.5, 0, t, MAP_HALF*2 + t*2],
	]
	for w in walls:
		var body := StaticBody2D.new()
		body.position = Vector2(w[0], w[1])
		var shape := CollisionShape2D.new()
		var rect  := RectangleShape2D.new()
		rect.size = Vector2(w[2], w[3])
		shape.shape = rect
		body.add_child(shape)
		add_child(body)

# ─── Лимиты камеры ───────────────────────────────────────────────────────────
func _setup_camera_limits() -> void:
	var player_node: Node = get_node_or_null("Player")
	if player_node == null: return
	var cam: Camera2D = player_node.get_node_or_null("Camera2D")
	if cam == null: return
	var mh: int = int(MAP_HALF)
	cam.limit_left   = -mh
	cam.limit_right  =  mh
	cam.limit_top    = -mh
	cam.limit_bottom =  mh

# ─── Здание ──────────────────────────────────────────────────────────────────
# Стоимость лечения за 1 ед. здоровья по зонам (растёт вместе с экономикой зоны)
const HEAL_COST_PER_HP := [10, 25, 45, 120, 220, 700, 3500, 30000, 180000]

func _spawn_building(d: Dictionary) -> void:
	var b = BuildingScene.instantiate()
	b.building_name        = d.name
	b.action_label         = d.action
	b.money_reward         = d.get("reward", 0)
	b.cooldown_seconds     = d.get("cd", 3.0)
	b.position             = _resolve_static_pos(d.pos, 130.0, 112.0)
	b.opens_business_shop  = d.get("biz", false)
	b.use_minigame         = d.get("minigame", false)
	b.is_heavy_labor       = d.get("heavy", false)
	b.food_shop_name       = d.get("food_shop", "")
	b.food_shop_items      = d.get("food_items", [])
	b.opens_education_shop = d.get("edu_shop", false)
	b.edu_req              = d.get("edu_req", 0)
	b.edu_max_level        = d.get("edu_max", 9)
	b.opens_travel_agency   = d.get("travel", false)
	b.opens_transport_shop  = d.get("transport_shop", false)
	b.opens_stock_ui        = d.get("stock", false)
	b.opens_radio_shop      = d.get("radio_shop", false)
	b.opens_real_estate     = d.get("realestate", false)
	b.opens_influence       = d.get("influence", false)
	if d.get("casino", false):
		b.money_reward = d.get("reward", 50000)
		b.is_casino    = true
	if d.get("heal", 0) > 0:
		b.heal_amount = d.get("heal", 0)
		var hz: int = clampi(d.get("zone", 0), 0, HEAL_COST_PER_HP.size() - 1)
		b.heal_cost = b.heal_amount * HEAL_COST_PER_HP[hz]

	var bc: Color = d.get("color", Color(0.4, 0.3, 0.1))
	var zone: int = d.get("zone", 0)
	var visual: ColorRect = b.get_node("Visual")
	visual.color = bc
	var has_tex: bool = d.has("tex") and d.tex != "" and ResourceLoader.exists(d.tex)

	# Тень (позади visual)
	var shadow := ColorRect.new()
	shadow.size = Vector2(126, 108)
	shadow.position = Vector2(-56, -44)
	shadow.color = Color(0.0, 0.0, 0.0, 0.32)
	b.add_child(shadow)
	b.move_child(shadow, 0)

	# Атмосферное свечение для элитных зон (5+)
	if zone >= 5:
		var glow := ColorRect.new()
		glow.size = Vector2(134, 116)
		glow.position = Vector2(-67, -58)
		glow.color = Color(bc.r, bc.g, bc.b, 0.13 + zone * 0.018)
		b.add_child(glow)
		b.move_child(glow, 0)

	# Неоновая рамка для казино
	if d.get("casino", false):
		var neon := ColorRect.new()
		neon.size = Vector2(130, 108)
		neon.position = Vector2(-65, -50)
		neon.color = Color(bc.r, bc.g, bc.b, 0.0)
		b.add_child(neon)
		var ntw := neon.create_tween()
		ntw.set_loops()
		ntw.tween_property(neon, "modulate:a", 1.0, 0.6)
		ntw.tween_property(neon, "modulate:a", 0.15, 0.8)
		# Неоновая линия сверху
		var neon_top := ColorRect.new()
		neon_top.size = Vector2(130, 3)
		neon_top.position = Vector2(-65, -50)
		neon_top.color = Color(minf(bc.r + 0.5, 1.0), minf(bc.g + 0.3, 1.0), minf(bc.b + 0.5, 1.0), 0.90)
		b.add_child(neon_top)
		var ntw2 := neon_top.create_tween()
		ntw2.set_loops()
		ntw2.tween_property(neon_top, "modulate:a", 1.0, 0.4)
		ntw2.tween_property(neon_top, "modulate:a", 0.2, 0.6)
		ntw2.tween_interval(0.1)

	# Крыша (только без текстуры)
	if not has_tex:
		var roof := ColorRect.new()
		roof.size = Vector2(120, 12)
		roof.position = Vector2(-60, -50)
		roof.color = bc.lightened(0.28)
		b.add_child(roof)
		var roof_accent := ColorRect.new()
		roof_accent.size = Vector2(120, 2)
		roof_accent.position = Vector2(-60, -38)
		roof_accent.color = bc.lightened(0.55)
		b.add_child(roof_accent)

	# Цвет окон по типу здания
	var wc: Color
	if d.get("casino", false):
		wc = Color(1.0, 0.75, 0.15, 0.90)
	elif d.get("biz", false):
		wc = Color(0.52, 0.70, 1.0, 0.80)
	elif d.get("realestate", false):
		wc = Color(0.55, 0.95, 0.65, 0.80)
	elif d.get("influence", false):
		wc = Color(0.85, 0.70, 1.0, 0.85)
	elif d.get("heal", 0) > 0:
		wc = Color(0.42, 0.90, 0.82, 0.80)
	elif d.get("edu_shop", false):
		wc = Color(0.70, 0.58, 1.0, 0.80)
	elif d.get("food_shop", "") != "":
		wc = Color(1.0, 0.78, 0.38, 0.80)
	elif zone >= 5:
		wc = Color(0.78, 0.70, 1.0, 0.82)
	else:
		wc = Color(0.90, 0.86, 0.52, 0.74)

	if not has_tex:
		# Сетка окон (2 ряда × 3 колонки)
		for row in 2:
			for col in 3:
				var win := ColorRect.new()
				win.size = Vector2(16, 11)
				win.position = Vector2(-60 + 12 + col * 32, -50 + 20 + row * 19)
				win.color = wc
				b.add_child(win)

		# Дверь
		var door := ColorRect.new()
		door.size = Vector2(18, 22)
		door.position = Vector2(-9, 27)
		door.color = Color(0.08, 0.06, 0.05, 1.0)
		b.add_child(door)
		var door_top := ColorRect.new()
		door_top.size = Vector2(22, 3)
		door_top.position = Vector2(-11, 24)
		door_top.color = bc.lightened(0.42)
		b.add_child(door_top)

		# Фонарики у входа (зоны 3+)
		if zone >= 3:
			var lamp_glow := ColorRect.new()
			lamp_glow.size = Vector2(18, 18)
			lamp_glow.position = Vector2(-9, 16)
			lamp_glow.color = Color(bc.r, bc.g, bc.b, 0.22)
			b.add_child(lamp_glow)
			var lamp_dot := ColorRect.new()
			lamp_dot.size = Vector2(6, 6)
			lamp_dot.position = Vector2(-3, 19)
			lamp_dot.color = Color(minf(bc.r + 0.45, 1.0), minf(bc.g + 0.35, 1.0), 0.90, 0.92)
			b.add_child(lamp_dot)

	# Текстура здания (заменяет процедурный визуал)
	if has_tex:
		# Цветная подложка под цвет здания — маскирует остатки фона на текстуре,
		# если где-то не до конца вычистилась "шахматка" прозрачности
		var tex_backing := ColorRect.new()
		tex_backing.size = Vector2(120, 98)
		tex_backing.position = Vector2(-60, -53)
		tex_backing.color = GROUND_BASE_COLORS[zone]
		b.add_child(tex_backing)
		var tex_sprite := Sprite2D.new()
		tex_sprite.texture = load(d.tex)
		tex_sprite.position = Vector2(0, -2)
		var tsz: Vector2 = tex_sprite.texture.get_size()
		tex_sprite.scale = Vector2(120.0 / tsz.x, 98.0 / tsz.y)
		b.add_child(tex_sprite)

	# Кусты у входа в зонах 2+
	if zone >= 2:
		for bx in [-52, 36]:
			var bush := Sprite2D.new()
			bush.texture = TEX_BUSH
			bush.position = Vector2(bx, 44)
			bush.scale = Vector2(0.62, 0.62)
			b.add_child(bush)

	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(120, 100)
	shape.shape = rect
	b.add_child(shape)

	# Вывеска с названием
	var sign_bg := ColorRect.new()
	sign_bg.size = Vector2(166, 22)
	sign_bg.position = Vector2(-83, -83)
	sign_bg.color = Color(0.04, 0.03, 0.07, 0.82)
	b.add_child(sign_bg)
	var sign_border := ColorRect.new()
	sign_border.size = Vector2(166, 2)
	sign_border.position = Vector2(-83, -85)
	sign_border.color = bc.lightened(0.22)
	b.add_child(sign_border)

	var name_lbl := Label.new()
	name_lbl.text = d.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(-81, -83)
	name_lbl.size = Vector2(162, 22)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.88, 0.96))
	name_lbl.add_theme_constant_override("outline_size", 2)
	name_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	b.add_child(name_lbl)

	$Buildings.add_child(b)

# ─── NPC ─────────────────────────────────────────────────────────────────────
func _spawn_npc(d: Dictionary) -> void:
	var npc = NPCScene.instantiate()
	npc.npc_name        = d.name
	npc.dialogues       = d.lines
	npc.title_dialogues = d.get("title_lines", [])
	npc.position        = d.pos

	# Скрываем заглушку и рисуем пиксельного персонажа
	npc.get_node("Visual").visible = false
	var nm: String = d.name
	var skin  := Color(0.92, 0.78, 0.62)
	var shirt := Color(0.40, 0.46, 0.62)
	var pants := Color(0.22, 0.25, 0.36)
	var hair  := Color(0.28, 0.22, 0.16)
	if   "👮" in nm: shirt = Color(0.22, 0.32, 0.66); pants = Color(0.18, 0.26, 0.55); hair = Color(0.18, 0.18, 0.22)
	elif "👵" in nm: shirt = Color(0.58, 0.38, 0.62); hair = Color(0.88, 0.88, 0.90); skin = Color(0.86, 0.74, 0.60)
	elif "🧒" in nm: shirt = Color(0.28, 0.62, 0.32); pants = Color(0.22, 0.36, 0.64); hair = Color(0.55, 0.35, 0.16)
	elif "👩" in nm: shirt = Color(0.72, 0.38, 0.55); hair = Color(0.88, 0.78, 0.30); skin = Color(0.95, 0.80, 0.65)
	elif "💼" in nm: shirt = Color(0.18, 0.18, 0.22); pants = Color(0.14, 0.14, 0.18); hair = Color(0.20, 0.18, 0.14)
	elif "🏖" in nm: shirt = Color(0.80, 0.65, 0.18); pants = Color(0.88, 0.84, 0.78); hair = Color(0.18, 0.15, 0.12)
	elif "🤴" in nm: shirt = Color(0.50, 0.22, 0.70); pants = Color(0.40, 0.18, 0.58); hair = Color(0.15, 0.12, 0.10)
	elif "🕴" in nm: shirt = Color(0.12, 0.12, 0.16); pants = Color(0.10, 0.10, 0.13); hair = Color(0.16, 0.14, 0.12)
	elif "👑" in nm: shirt = Color(0.14, 0.12, 0.20); pants = Color(0.12, 0.10, 0.16); hair = Color(0.58, 0.48, 0.12)
	elif "🧔" in nm: shirt = Color(0.38, 0.44, 0.38); hair = Color(0.50, 0.44, 0.38)
	elif "🧑" in nm: shirt = Color(0.18, 0.20, 0.28); hair = Color(0.22, 0.20, 0.18)

	# Тень под ногами
	var shd := ColorRect.new()
	shd.size = Vector2(28, 7); shd.position = Vector2(-14, 22)
	shd.color = Color(0.0, 0.0, 0.0, 0.28); npc.add_child(shd)
	# Ботинки
	for sx: int in [-13, 5]:
		var shoe := ColorRect.new()
		shoe.size = Vector2(9, 7); shoe.position = Vector2(sx, 16)
		shoe.color = Color(0.14, 0.12, 0.10); npc.add_child(shoe)
	# Ноги
	for lx: int in [-11, 4]:
		var leg := ColorRect.new()
		leg.size = Vector2(7, 17); leg.position = Vector2(lx, 1)
		leg.color = pants; npc.add_child(leg)
	# Тело
	var body := ColorRect.new()
	body.size = Vector2(26, 20); body.position = Vector2(-13, -17)
	body.color = shirt; npc.add_child(body)
	var collar := ColorRect.new()
	collar.size = Vector2(26, 2); collar.position = Vector2(-13, -17)
	collar.color = shirt.lightened(0.24); npc.add_child(collar)
	# Голова
	var head := ColorRect.new()
	head.size = Vector2(20, 14); head.position = Vector2(-10, -31)
	head.color = skin; npc.add_child(head)
	# Волосы / шапка
	var hair_r := ColorRect.new()
	hair_r.size = Vector2(22, 7); hair_r.position = Vector2(-11, -38)
	hair_r.color = hair; npc.add_child(hair_r)
	# Глаза
	for ex: int in [-7, 4]:
		var eye := ColorRect.new()
		eye.size = Vector2(3, 3); eye.position = Vector2(ex, -27)
		eye.color = Color(0.12, 0.10, 0.08); npc.add_child(eye)

	# Бейдж с именем над персонажем
	var name_bg := ColorRect.new()
	name_bg.size = Vector2(108, 18); name_bg.position = Vector2(-54, -58)
	name_bg.color = Color(0.04, 0.03, 0.07, 0.78); npc.add_child(name_bg)
	var name_lbl := Label.new()
	name_lbl.text = d.name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(-52, -58); name_lbl.size = Vector2(104, 18)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 0.96))
	name_lbl.add_theme_constant_override("outline_size", 2)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	npc.add_child(name_lbl)

	var shape := CollisionShape2D.new()
	var rect  := RectangleShape2D.new()
	rect.size = Vector2(50, 60)
	shape.shape = rect
	npc.add_child(shape)

	$Buildings.add_child(npc)

	# Лёгкое покачивание персонажа
	var base_y: float = npc.position.y
	var bob_offset: float = randf_range(0.0, TAU)
	var bob_tw := npc.create_tween()
	bob_tw.set_loops()
	bob_tw.tween_method(func(v: float): npc.position.y = base_y + sin(v) * 2.5,
		bob_offset, bob_offset + TAU, randf_range(1.8, 2.6))

# ─── Подбор тира жилого дома: 80% своя зона, 10% беднее, 10% богаче ─────────
func _roll_house_tier(zone: int, pos: Vector2) -> int:
	var h: int = hash(Vector2i(pos)) % 100
	if h < 0:
		h += 100
	var max_tier: int = ZONE_HOUSE_TEX.size() - 1
	if h < 80:
		return zone
	elif h < 90:
		return maxi(0, zone - 1)
	else:
		return mini(max_tier, zone + 1)

# ─── Декоративные здания ──────────────────────────────────────────────────────
func _spawn_deco_for_zone(zone: int, center: Vector2) -> void:
	var _car_pool: Array = [TEX_CAR_SEDAN, TEX_CAR_MINI, TEX_CAR_MUSCLE]
	for d in DECO_ZONES[zone]:
		var node := Node2D.new()
		node.position = center + d.pos
		$Districts.add_child(node)

		var emoji: String = d.get("emoji", "")

		# ── Деревья — реальные спрайты ──────────────────────────────────────
		if emoji == "🌳" or emoji == "🌲":
			var tex: Texture2D = TEX_TREE_BIG if emoji == "🌳" else TEX_TREE_MINI
			var sp := Sprite2D.new()
			sp.texture = tex
			var tw: float = float(tex.get_width())
			var th: float = float(tex.get_height())
			sp.scale = Vector2(d.w / tw, d.h / th)
			node.add_child(sp)
			continue

		# ── Мусорные баки — реальные спрайты ────────────────────────────────
		if emoji == "🗑":
			var sp := Sprite2D.new()
			sp.texture = TEX_TRASHCAN
			sp.scale = Vector2(d.w / 32.0, d.h / 32.0)
			node.add_child(sp)
			# Мелкая подпись
			if d.get("label", "") != "":
				var lbl := Label.new()
				lbl.text = d.label
				lbl.position = Vector2(-20, d.h * 0.5 + 2)
				lbl.add_theme_font_size_override("font_size", 8)
				lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.6))
				node.add_child(lbl)
			continue

		# ── Жилые/промышленные здания — спрайт зонального типа ────────────
		if (emoji == "🏢" or emoji == "🏠" or emoji == "🏘" or emoji == "🏰" or emoji == "🏡" or emoji == "🏯" or emoji == "🏭") and not d.get("label", "").contains("стройка") and not d.get("label", "").contains("Таунхаус"):
			# Не даём дому встать на дорогу или влезть в другое здание
			node.position = _resolve_static_pos(node.position, d.w, d.h)
			var sp := Sprite2D.new()
			var house_tex: Texture2D
			var house_tier: int = zone
			if d.has("tex") and d.tex != "" and ResourceLoader.exists(d.tex):
				house_tex = load(d.tex)
			elif emoji == "🏭":
				house_tex = TEX_BUILDING
			else:
				# Жилой дом: 80% своя зона, 10% на тир беднее, 10% на тир богаче
				house_tier = _roll_house_tier(zone, d.pos)
				var ztex_path: String = ZONE_HOUSE_TEX[house_tier]
				if ResourceLoader.exists(ztex_path):
					house_tex = load(ztex_path)
				elif emoji == "🏢":
					house_tex = TEX_HOUSE_PANEL9
				elif house_tier == 0:
					house_tex = TEX_HOUSE_KHRUSH
				elif house_tier == 1:
					house_tex = TEX_HOUSE_BARAK
				else:
					house_tex = TEX_HOUSE_BRICK5
			sp.texture = house_tex
			var tw: float = float(house_tex.get_width())
			var th: float = float(house_tex.get_height())
			var scale_fit: float = minf(d.w / tw, d.h / th)
			sp.scale = Vector2(scale_fit, scale_fit)
			# Тонировка зависит от тира конкретного дома, а не от зоны
			var tint: Color
			if house_tier == 0:
				tint = d.color.lightened(0.15)
			elif house_tier == 1:
				tint = d.color.darkened(0.05)
				if emoji == "🏭":
					tint = Color(0.36, 0.32, 0.28)
			else:
				tint = Color(1.0, 1.0, 1.0)  # без тонировки — текстура сама по себе
			tint.a = 1.0
			sp.modulate = tint
			# Цветная подложка под цвет дома — маскирует остатки фона на текстуре
			var backing := ColorRect.new()
			var bw: float = tw * scale_fit
			var bh: float = th * scale_fit
			backing.size = Vector2(bw, bh)
			backing.position = Vector2(-bw * 0.5, -bh * 0.5)
			backing.color = GROUND_BASE_COLORS[zone]
			node.add_child(backing)
			node.add_child(sp)
			# Подпись с номером/названием
			var lbl := Label.new()
			lbl.text = d.get("label", "")
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.position = Vector2(-40, -d.h * 0.5 - 20)
			lbl.add_theme_font_size_override("font_size", 9)
			lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.80, 0.85))
			lbl.add_theme_constant_override("outline_size", 2)
			lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
			node.add_child(lbl)
			continue

		# ── Парковки — асфальт + припаркованные машины ──────────────────────
		if emoji == "🅿":
			var body := ColorRect.new()
			body.size = Vector2(d.w, d.h)
			body.position = Vector2(-d.w * 0.5, -d.h * 0.5)
			body.color = d.color
			node.add_child(body)
			# Разметка парковочных мест
			var slots: int = maxi(1, int(d.w / 70.0))
			for si in slots:
				var line := ColorRect.new()
				line.size = Vector2(2, d.h - 6)
				line.position = Vector2(-d.w * 0.5 + si * (d.w / slots), -d.h * 0.5 + 3)
				line.color = Color(1, 1, 1, 0.25)
				node.add_child(line)
			# Припаркованные машины (через одно место)
			for ci in range(0, slots - 1, 2):
				var car := Sprite2D.new()
				car.texture = _car_pool[ci % _car_pool.size()]
				car.scale = Vector2(0.55, 0.55)
				car.position = Vector2(-d.w * 0.5 + (ci + 0.5) * (d.w / slots), 0)
				node.add_child(car)
			continue

		# ── Гаражи — текстура бокса, либо запасной цветной прямоугольник ───
		if emoji == "🚗" and d.get("label", "") == "Гараж":
			var garage_path := "res://assets/textures/garage.png"
			if ResourceLoader.exists(garage_path):
				var gtex: Texture2D = load(garage_path)
				var gsp := Sprite2D.new()
				gsp.texture = gtex
				gsp.scale = Vector2(d.w / float(gtex.get_width()), d.h / float(gtex.get_height()))
				node.add_child(gsp)
			else:
				var body := ColorRect.new()
				body.size = Vector2(d.w, d.h)
				body.position = Vector2(-d.w * 0.5, -d.h * 0.5)
				body.color = d.color
				node.add_child(body)
				# Дверь гаража
				var door := ColorRect.new()
				door.size = Vector2(d.w - 8, 10)
				door.position = Vector2(-d.w * 0.5 + 4, d.h * 0.5 - 12)
				door.color = Color(0.18, 0.18, 0.20)
				node.add_child(door)
			continue

		# ── Дымовые трубы — труба + клубы дыма ──────────────────────────────
		if emoji == "💨":
			var chimney := ColorRect.new()
			chimney.size = Vector2(d.w, d.h)
			chimney.position = Vector2(-d.w * 0.5, -d.h * 0.5)
			chimney.color = d.color
			node.add_child(chimney)
			var ch_top := ColorRect.new()
			ch_top.size = Vector2(d.w + 6, 5)
			ch_top.position = Vector2(-d.w * 0.5 - 3, -d.h * 0.5)
			ch_top.color = d.color.lightened(0.22)
			node.add_child(ch_top)
			for i in 7:
				var puff := ColorRect.new()
				var pw: float = 13.0 + i * 4.0
				puff.size = Vector2(pw, pw)
				var bx2: float = -pw * 0.5 + i * 2.5
				var by2: float = -d.h * 0.5 - 12.0 - i * 14.0
				puff.position = Vector2(bx2, by2)
				puff.color = Color(0.72, 0.70, 0.68, maxf(0.0, 0.40 - i * 0.052))
				node.add_child(puff)
				# Анимация: клубы дыма медленно поднимаются, гаснут, сбрасываются
				var ptw := puff.create_tween()
				ptw.set_loops()
				var stagger: float = randf_range(0.0, 2.8)
				ptw.tween_callback(func(): puff.position = Vector2(bx2, by2); puff.modulate.a = 0.0)
				ptw.tween_interval(stagger)
				ptw.tween_property(puff, "modulate:a", maxf(0.0, 0.40 - i * 0.052), 0.5)
				ptw.set_parallel(true)
				var rise: float = 24.0 + i * 5.0
				ptw.tween_property(puff, "position:y", by2 - rise, 2.4 + i * 0.35).set_ease(Tween.EASE_OUT)
				ptw.tween_property(puff, "position:x", bx2 + randf_range(-6, 6), 2.4 + i * 0.35)
				ptw.tween_property(puff, "modulate:a", 0.0, 1.0).set_delay(1.4 + i * 0.18)
				ptw.set_parallel(false)
				ptw.tween_interval(0.05)
			continue

		# ── Бассейн — синяя вода с анимированными полосами ─────────────────
		if emoji == "🏊":
			# Бортик
			var rim := ColorRect.new()
			rim.size = Vector2(d.w + 10, d.h + 10)
			rim.position = Vector2(-d.w * 0.5 - 5, -d.h * 0.5 - 5)
			rim.color = Color(0.72, 0.70, 0.65)
			node.add_child(rim)
			# Вода
			var water := ColorRect.new()
			water.size = Vector2(d.w, d.h)
			water.position = Vector2(-d.w * 0.5, -d.h * 0.5)
			water.color = Color(0.12, 0.48, 0.82)
			node.add_child(water)
			# Блики/волны (горизонтальные полосы)
			var wave_count: int = maxi(3, int(d.h / 14.0))
			for wi in wave_count:
				var wave := ColorRect.new()
				wave.size = Vector2(d.w - 8, 4)
				wave.position = Vector2(-d.w * 0.5 + 4, -d.h * 0.5 + 6 + wi * 14)
				wave.color = Color(0.55, 0.82, 1.0, 0.38)
				node.add_child(wave)
				# Анимация: волна смещается по X туда-сюда
				var wtw := wave.create_tween()
				wtw.set_loops()
				var shift: float = randf_range(4.0, 10.0)
				var period: float = randf_range(1.2, 2.4)
				var phase_offset: float = randf_range(0.0, PI)
				wtw.tween_method(func(v: float):
					wave.position.x = -d.w * 0.5 + 4 + sin(v + phase_offset) * shift,
					0.0, TAU, period)
			# Подпись
			var lbl_p := Label.new()
			lbl_p.text = "🏊  " + d.get("label", "")
			lbl_p.position = Vector2(-d.w * 0.5, -d.h * 0.5 - 22)
			lbl_p.size = Vector2(d.w, 20)
			lbl_p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl_p.add_theme_font_size_override("font_size", 11)
			lbl_p.add_theme_color_override("font_color", Color(0.72, 0.92, 1.0, 0.92))
			lbl_p.add_theme_constant_override("outline_size", 2)
			lbl_p.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
			node.add_child(lbl_p)
			continue

		# ── Сквер/газон — мягкий зелёный участок без "окон" ─────────────────
		if emoji == "🌿":
			# Не даём скверу встать прямо на дорогу
			node.position = _resolve_static_pos(node.position, d.w, d.h)
			var lawn := ColorRect.new()
			lawn.size = Vector2(d.w, d.h)
			lawn.position = Vector2(-d.w * 0.5, -d.h * 0.5)
			lawn.color = d.color
			node.add_child(lawn)
			# Лёгкая текстурная рябь травы (случайные мазки потемнее/светлее)
			var blade_rng := RandomNumberGenerator.new()
			blade_rng.seed = hash(d.pos)
			for _i in int(d.w * d.h / 1400.0):
				var bx: float = blade_rng.randf_range(-d.w * 0.5 + 4, d.w * 0.5 - 4)
				var by: float = blade_rng.randf_range(-d.h * 0.5 + 4, d.h * 0.5 - 4)
				var blade := ColorRect.new()
				var bsz: float = blade_rng.randf_range(10, 24)
				blade.size = Vector2(bsz, bsz)
				blade.position = Vector2(bx, by)
				var shade: float = blade_rng.randf_range(-0.06, 0.08)
				blade.color = Color(clampf(d.color.r + shade, 0, 1), clampf(d.color.g + shade, 0, 1), clampf(d.color.b + shade, 0, 1), 0.55)
				node.add_child(blade)
			if d.get("label", "") != "":
				var lawn_lbl := Label.new()
				lawn_lbl.text = d.label
				lawn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lawn_lbl.position = Vector2(-d.w * 0.5, -d.h * 0.5 - 20)
				lawn_lbl.size = Vector2(d.w, 18)
				lawn_lbl.add_theme_font_size_override("font_size", 11)
				lawn_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.80, 0.85))
				lawn_lbl.add_theme_constant_override("outline_size", 2)
				lawn_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
				node.add_child(lawn_lbl)
			continue

		# ── Цветники — кластер мягких кружков вместо плоского прямоугольника ──
		if emoji == "🌸" or emoji == "🌺":
			var fl_rng := RandomNumberGenerator.new()
			fl_rng.seed = hash(d.pos)
			var petal_count: int = maxi(5, int(d.w * d.h / 90.0))
			for _i in petal_count:
				var fx: float = fl_rng.randf_range(-d.w * 0.5, d.w * 0.5)
				var fy: float = fl_rng.randf_range(-d.h * 0.5, d.h * 0.5)
				var psz: float = fl_rng.randf_range(5, 10)
				var petal := ColorRect.new()
				petal.size = Vector2(psz, psz)
				petal.position = Vector2(fx - psz * 0.5, fy - psz * 0.5)
				petal.color = d.color.lightened(fl_rng.randf_range(-0.1, 0.2))
				node.add_child(petal)
			continue

		# ── Простые пропсы с готовой текстурой (скамейка, беседка, фонтан и т.п.) ──
		var simple_tex_path: String = ""
		if emoji == "🪑":
			simple_tex_path = "res://assets/textures/bench.png"
		elif emoji == "⛺":
			simple_tex_path = "res://assets/textures/gazebo.png"
		elif emoji == "⛲":
			simple_tex_path = "res://assets/textures/fountain.png"
		elif emoji == "🗿":
			simple_tex_path = "res://assets/textures/monument.png"
		elif emoji == "🛝":
			simple_tex_path = "res://assets/textures/playground.png"
		elif emoji == "🏀":
			simple_tex_path = "res://assets/textures/sport_court.png"
		elif emoji == "🛢":
			simple_tex_path = "res://assets/textures/barrels_tank.png"
		elif emoji == "🏗" and d.get("label", "") == "Стройплощадка":
			simple_tex_path = "res://assets/textures/construction_site.png"
		elif emoji == "🎭":
			simple_tex_path = "res://assets/textures/dom_kultury.png"
		elif emoji == "⛪":
			simple_tex_path = "res://assets/textures/church.png"
		elif emoji == "🚌" and d.get("label", "").begins_with("ост."):
			simple_tex_path = "res://assets/textures/bus_stop.png"
		elif emoji == "🏪" and d.get("label", "").begins_with("Рынок"):
			simple_tex_path = "res://assets/textures/Rynok.png"
		elif emoji == "🍺" and d.get("label", "").contains("Факел"):
			simple_tex_path = "res://assets/textures/pivnaya.png"
		elif emoji == "🏥" and d.get("label", "") == "Медпункт":
			simple_tex_path = "res://assets/textures/medpunkt.png"
		elif emoji == "🚛" and d.get("label", "") == "Склад №7":
			simple_tex_path = "res://assets/textures/sklad.png"
		elif emoji == "🏫" and d.get("label", "").begins_with("Школа"):
			simple_tex_path = "res://assets/textures/Shcolla.png"
		elif emoji == "🏬":
			simple_tex_path = "res://assets/textures/mall.png"
		elif emoji == "🏟":
			simple_tex_path = "res://assets/textures/sport_complex.png"
		elif emoji == "🏘" and d.get("label", "").contains("Таунхаус"):
			simple_tex_path = "res://assets/textures/townhouse.png"
		elif emoji == "📮":
			simple_tex_path = "res://assets/textures/post_office.png"
		elif emoji == "🏪" or emoji == "💈":
			simple_tex_path = "res://assets/textures/shop_small.png"
		elif emoji == "🏛":
			var lbl_l: String = d.get("label", "")
			if lbl_l.contains("Корпус") or lbl_l.contains("Факультет") or lbl_l.contains("Библиотека") or lbl_l.contains("Университет") or lbl_l.contains("Академия"):
				simple_tex_path = "res://assets/textures/Univerciti.png"
			elif lbl_l.contains("Конгресс"):
				simple_tex_path = "res://assets/textures/Board of directors.png"
			elif lbl_l.contains("ЦБ") or lbl_l.contains("Госбанк"):
				simple_tex_path = "res://assets/textures/Generic bank branch building.png"
			elif lbl_l.contains("Парламент") or lbl_l.contains("Министерство"):
				simple_tex_path = "res://assets/textures/Russian Ministry of Finance building.png"
		elif emoji == "⛽":
			if d.get("label", "").begins_with("Цистерна"):
				simple_tex_path = "res://assets/textures/barrels_tank.png"
			else:
				simple_tex_path = "res://assets/textures/gas_station.png"
		if simple_tex_path != "" and ResourceLoader.exists(simple_tex_path):
			# Не даём объекту встать на дорогу (многие стоят на x=0/y=0 — там у каждой зоны проходит магистраль)
			node.position = _resolve_static_pos(node.position, d.w, d.h)
			# Цветная подложка под цвет объекта — маскирует остатки фона на текстуре
			var sbacking := ColorRect.new()
			sbacking.size = Vector2(d.w, d.h)
			sbacking.position = Vector2(-d.w * 0.5, -d.h * 0.5)
			sbacking.color = GROUND_BASE_COLORS[zone]
			node.add_child(sbacking)
			var stex: Texture2D = load(simple_tex_path)
			var ssp := Sprite2D.new()
			ssp.texture = stex
			var stw: float = float(stex.get_width())
			var sth: float = float(stex.get_height())
			# Пропорциональное масштабирование — не сплющиваем текстуру под произвольный footprint
			if emoji == "🪑" and d.h > d.w:
				ssp.rotation_degrees = 90.0
				var sfit_r: float = minf(d.h / stw, d.w / sth)
				ssp.scale = Vector2(sfit_r, sfit_r)
			else:
				var sfit: float = minf(d.w / stw, d.h / sth)
				ssp.scale = Vector2(sfit, sfit)
			node.add_child(ssp)
			if d.get("label", "") != "":
				var slbl := Label.new()
				slbl.text = d.label
				slbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				slbl.position = Vector2(-d.w * 0.5, -d.h * 0.5 - 18)
				slbl.size = Vector2(d.w, 16)
				slbl.add_theme_font_size_override("font_size", 10)
				slbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.85, 0.90))
				slbl.add_theme_constant_override("outline_size", 2)
				slbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
				node.add_child(slbl)
			continue

		# ── По умолчанию: здание с деталями по уровню зоны ─────────────────
		# Тень
		var shadow2 := ColorRect.new()
		shadow2.size = Vector2(d.w + 6, d.h + 8)
		shadow2.position = Vector2(-d.w * 0.5 + 4, -d.h * 0.5 + 6)
		shadow2.color = Color(0.0, 0.0, 0.0, 0.28)
		node.add_child(shadow2)

		# Свечение для элитных зон (5+)
		if zone >= 5:
			var glow2 := ColorRect.new()
			glow2.size = Vector2(d.w + 14, d.h + 14)
			glow2.position = Vector2(-d.w * 0.5 - 7, -d.h * 0.5 - 7)
			glow2.color = Color(d.color.r, d.color.g, d.color.b, 0.15 + zone * 0.014)
			node.add_child(glow2)
			node.move_child(glow2, 0)

		var body2 := ColorRect.new()
		body2.size = Vector2(d.w, d.h)
		body2.position = Vector2(-d.w * 0.5, -d.h * 0.5)
		body2.color = d.color
		node.add_child(body2)

		# Крыша
		var roof_h: int = maxi(8, int(d.h * 0.12))
		var roof2 := ColorRect.new()
		roof2.size = Vector2(d.w, roof_h)
		roof2.position = Vector2(-d.w * 0.5, -d.h * 0.5)
		roof2.color = d.color.lightened(0.30)
		node.add_child(roof2)
		var roof_line2 := ColorRect.new()
		roof_line2.size = Vector2(d.w, 2)
		roof_line2.position = Vector2(-d.w * 0.5, -d.h * 0.5 + roof_h)
		roof_line2.color = d.color.lightened(0.55)
		node.add_child(roof_line2)

		# Цвет окон по зоне
		var win_col2: Color
		if zone <= 1:
			win_col2 = Color(0.90, 0.84, 0.48, 0.68)
		elif zone <= 3:
			win_col2 = Color(0.88, 0.90, 0.58, 0.72)
		elif zone <= 5:
			win_col2 = Color(0.58, 0.78, 1.00, 0.74)
		else:
			win_col2 = Color(0.82, 0.68, 1.00, 0.80)

		var wcols := maxi(1, int(d.w / 26.0))
		var wrows := maxi(1, int(d.h / 20.0))
		for r in mini(wrows, 5):
			for c in mini(wcols, 6):
				var win2 := ColorRect.new()
				win2.size = Vector2(11, 9)
				win2.position = Vector2(-d.w*0.5 + 9 + c*17, -d.h*0.5 + roof_h + 5 + r*15)
				win2.color = win_col2
				node.add_child(win2)
				# Редкое мигание окон (зона 3+, 18% вероятность)
				if zone >= 3 and randf() < 0.18:
					var ftw := win2.create_tween()
					ftw.set_loops()
					ftw.tween_interval(randf_range(3.5, 11.0))
					ftw.tween_property(win2, "modulate:a", 0.04, 0.06)
					ftw.tween_interval(randf_range(0.04, 0.18))
					ftw.tween_property(win2, "modulate:a", 1.0, 0.05)
					ftw.tween_interval(randf_range(5.0, 16.0))

		# Дверь (если здание достаточно высокое)
		if d.h >= 60:
			var door2 := ColorRect.new()
			door2.size = Vector2(14, 18)
			door2.position = Vector2(-7, d.h * 0.5 - 20)
			door2.color = Color(0.08, 0.06, 0.05, 1.0)
			node.add_child(door2)

		# Кусты у здания в зонах 2+
		if zone >= 2 and d.h >= 70:
			for bx in [-d.w * 0.5 - 10.0, d.w * 0.5 - 6.0]:
				var bush2 := Sprite2D.new()
				bush2.texture = TEX_BUSH
				bush2.position = Vector2(bx, d.h * 0.5 - 12)
				bush2.scale = Vector2(0.68, 0.68)
				node.add_child(bush2)

		var lbl2 := Label.new()
		lbl2.text = emoji + "  " + d.get("label", "")
		lbl2.position = Vector2(-d.w * 0.5, -d.h * 0.5 - 22)
		lbl2.size = Vector2(d.w, 20)
		lbl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl2.add_theme_font_size_override("font_size", 11)
		lbl2.add_theme_color_override("font_color", Color(0.96, 0.96, 0.82, 0.90))
		lbl2.add_theme_constant_override("outline_size", 2)
		lbl2.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
		node.add_child(lbl2)
