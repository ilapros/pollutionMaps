import urllib2
import requests
from bs4 import BeautifulSoup
import csv
import re


writer = csv.writer(open('test_pollution_2.csv', 'a'), delimiter=' ')
writer.writerow(['stations', 'latitudes', 'longitudes', 'previsions'])

#reader = csv.reader(open('test_pollution_2.csv', 'a'), delimiter=' ')
reader = csv.reader(open('test_pollution_2.csv', 'rb'), delimiter='\t')
next(reader, None)

writer2 = csv.writer(open('test_pollution_3.csv', 'a'), delimiter=' ')
writer2.writerow(['stations', 'latitudes', 'longitudes', 'day 0', 'day 1', 'day 2', 'day3', 'day 4'])


def write_csv_coord():
    # Get the RSS feed of pollution previsions:
    print "Retrieving data from RSS feeds"
    print "..."
    rss_feed = urllib2.urlopen("http://uk-air.defra.gov.uk/assets/rss/forecast.xml").read()
    # Parse the data
    # write data to csv
    soup = BeautifulSoup(rss_feed)
    for s in soup.find_all('item'):
        name = s.title.string
        # Use GoogleMaps api to get coordinates
        remove = re.compile("([A-Za-z.]+)")
        clean_name = remove.sub("", name).strip()
        print "Getting coordinates for " + name
        if len(name.split(' ')) == 1:
            url = "https://maps.googleapis.com/maps/api/geocode/json?address=" + name.split(' ')[0] + "+UK"
        if len(name.split(' ')) > 1:
            url = "https://maps.googleapis.com/maps/api/geocode/json?address=" + name.split(' ')[0] + "+" + name.split(' ')[1] + "+UK"
        loc_info = requests.get(url)
        loc_dict = loc_info.json()
        try:
            coord = loc_dict.get("results")[0]["geometry"]["location"]
        except IndexError:
            pass
        desc = s.description.string
        l, foo, p = desc.split('<br />')
        #l = str(l).replace('Location: ', '')
        #lat, lon = l.split(' ')[0].strip(), l.split(' ')[1].strip()
        lat, lon = coord["lat"], coord["lng"]
        #print lat
        writer.writerow([name, lat, lon, p])

def modif_csv_previsions():
    print "Reading coordinate from file"
    print "..."
    for row in reader:
        try:
            row = row[0].split(',')
            tmp = row[3].split(' ')
            prevs = [tmp[1], tmp[3], tmp[5], tmp[7], tmp[9]]
            new_row = row[0:3] + prevs
            writer2.writerow(new_row)
        except IndexError:
            pass
        


if __name__ == "__main__":
     modif_csv_previsions()   
