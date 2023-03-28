import pymongo
import random

client = pymongo.MongoClient('localhost', 27017)
db = client['cpu_index']
collection = db['shuffle']

obj = {}
a = [x for x in range(10000)]
random.shuffle(a)

for i in range(10000):
    collection.insert({'index': i, 'value': a[i]})
# print(obj)