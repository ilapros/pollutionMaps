import urllib2
from bs4 import BeautifulSoup
import csv

# Get the RSS feed of pollution previsions:

rss_feed = urllib2.urlopen("http://uk-air.defra.gov.uk/assets/rss/forecast.xml").read()

# Parse the data
# write data to csv
writer = csv.writer(open('test_pollution.csv', 'a'), delimiter=' ')
writer.writerow(['stations', 'locations', 'previsions'])

stations, loc, prev = ['stations'], ['location'], ['previsions']
info = []

soup = BeautifulSoup(rss_feed)
for s in soup.find_all('item'):
    name = s.title.string
    stations.append(name)
    desc = s.description.string
    l, foo, p = desc.split('<br />')
    loc.append(l)
    prev.append(p)
    writer.writerow([name, l, p])

