
# This is a massive hack, do not use it.

## Why:

I needed to be able to find images easily in a big network share containing a few thousand images.  Finder took forever, anything else I tried sucked, beachballed a lot, or otherwise pissed me off.

Knocked up something quick to see how performant it would be.  Initial indexing will be slow, but will run incrementally thereafter.  I just cron it.

It takes a while to index, but after that the viewer is nice and snappy.

## Setup:

1. Install [python-nominatim](https://github.com/rdeguzman/python-nominatim.git)
2. Install exiftool (homebrew on OSX)
3. Install imagemagick (homebrew on OSX)

## Usage:

Indexing creates 2 sqlite3 databases:

1. geocache.db contains cached reverse geolookups to play nice with Nominatim
2. photos.db contains thumbs, bit of exif meta, and copies of geocache data

To create/update the index (previously indexed files will be skipped over)

```
for i in /Some/Place/*JPG; do echo $i; python indexer.py "$i"; done
```

Note that any uncached geolookup will sleep for 3 seconds afterwards to avoid hammering their API.


## XCode App:

Change MasterViewController.m:findPhotos() to match the location of your photos.db file.

Search box searches against SQL date strings, and location.

### Example Searches:

+ **2013** *(Taken in 2013)*
+ **2014-03** *(Taken in March 2014)*
+ **Oxford** *(Taken in Oxford)*
+ **Sweden** *(Taken in Sweden)*

#### Credit:

XCode app is literally a hacked up version of the ScaryBugsApp tutorial by Ray Wenderlich:
[Tutorial Link](http://www.raywenderlich.com/1797/ios-tutorial-how-to-create-a-simple-iphone-app-part-1)

