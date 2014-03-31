#!/usr/bin/env python

import sys, subprocess, os, time, sqlite3, re, json, datetime, time
from dateutil import parser
from nominatim import ReverseGeocoder

def create_schema(c):
	c.execute("CREATE TABLE IF NOT EXISTS photos (filename text, thumb blob, exif_create_date text, latitude text, longitude text, PRIMARY KEY(filename))");
	c.execute("CREATE TABLE IF NOT EXISTS geo (latitude text, longitude text, address text, city text, country text, PRIMARY KEY(latitude, longitude))");

def gps_to_decimal(d, direction):
	result = round(float(d[0]) + (float(d[1]) / 60.0) + (float(d[2]) / 3600.0), 6)

	if( (direction == "S") or (direction == "W")):
		result = -result

	return result


def get_gps(s):
	m = re.match(r"^(\d+)\sdeg\s(\d+)'\s(\d+.\d+)\"\s(\w)\D+(\d+)\sdeg\s(\d+)'\s(\d+.\d+)\"\s(\w)$", s)
	if m:
		return gps_to_decimal(m.group(1, 2, 3), m.group(4)), gps_to_decimal(m.group(5, 6, 7), m.group(8))

	return None

def get_location(latitude, longitude):
	db = sqlite3.connect("geocache.db")
	c = db.cursor()
	c.execute("CREATE TABLE IF NOT EXISTS geo (latitude text, longitude text, address text, city text, country text, primary key(latitude, longitude))")
	c.execute("SELECT address, city, country FROM geo WHERE latitude=? AND longitude=?", (latitude, longitude))
	row = c.fetchone()

	if row:
		return (latitude, longitude, row[0], row[1], row[2])

	client = ReverseGeocoder("http://nominatim.openstreetmap.org/reverse?format=json")
	response = client.geocode(latitude, longitude)

	print "*"

	city = None
	country = None
	address = None

	if response:
		address_keys = response["address"].keys()

		if "city" in address_keys:
			city = response["address"]["city"]

		if "country" in address_keys:
			country = response["address"]["country"]

		c.execute("INSERT OR IGNORE INTO geo (latitude, longitude, address, city, country) VALUES (?, ?, ?, ?, ?)", (latitude, longitude, response["full_address"], city, country))
		db.commit()

	db.close()

	# Don't hammer nominatim
	time.sleep(3)

	return (latitude, longitude, response["full_address"], city, country)

def fix_date(d):
	return d.replace(":", "-", 2)


if len(sys.argv) < 2:
	sys.exit("Usage: %s" % sys.argv[0])

filename = os.path.abspath(sys.argv[1])

db = sqlite3.connect("photos.db")
dbc = db.cursor()
create_schema(dbc)

dbc.execute("SELECT COUNT(*) FROM photos WHERE filename=?", (filename,))
if dbc.fetchone()[0] > 0:
	db.close()
	sys.exit()

p_thumb = subprocess.Popen(["convert", "-define", "jpg:size=200x200", "-auto-orient", "-strip", "-thumbnail", "100x100>", filename, "gif:-"], stdout=subprocess.PIPE)
p_exif = subprocess.Popen(["exiftool", "-j", filename], stdout=subprocess.PIPE)

thumb = p_thumb.communicate()[0]
exif = json.loads(p_exif.communicate()[0])[0]
exif_keys = exif.keys()

create_date = None
latitude = None
longitude = None
geodata = None

if "CreateDate" in exif_keys:
	create_date = parser.parse(fix_date(exif["CreateDate"])).strftime("%Y-%m-%d %H:%M:%S")
elif "FileModifyDate" in exif_keys:
	create_date = parser.parse(fix_date(exif["FileModifyDate"])).strftime("%Y-%m-%d %H:%M:%S")

if "GPSPosition" in exif_keys:
	latitude, longitude = get_gps(exif["GPSPosition"])
	geodata = get_location(latitude, longitude)

dbc.execute("INSERT OR IGNORE INTO photos (filename, thumb, exif_create_date, latitude, longitude) VALUES (?, ?, ?, ?, ?)", (filename, thumb, create_date, latitude, longitude))

if geodata:
	dbc.execute("INSERT OR IGNORE INTO geo (latitude, longitude, address, city, country) VALUES (?, ?, ?, ?, ?)", geodata)

db.commit()
db.close()

