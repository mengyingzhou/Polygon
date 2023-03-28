import pymongo
import random
import time
import sys

client = pymongo.MongoClient('localhost', 27017)
db = client['cpu_index']
collection = db['shuffle']

def get_ms():
    ct = time.time()
    local_time = time.localtime(ct)
    data_head = int(time.strftime('%Y%m%d%H%M%S', local_time)) + 80000
    data_secs = (ct - int(ct)) * 1000
    time_stamp = "%s.%03d" % (str(data_head), data_secs)
    return time_stamp

if len(sys.argv) > 1:
    print(sys.argv[1])
    f_out = open("/home/gtc/FastRoute/server/cpu_query.txt", "a")
ori_time = get_ms()
n = random.randint(50, 100)
n = 1
print(n)
ori_time = get_ms()
print("start_time: ", ori_time)
if len(sys.argv) > 1:
    f_out("start_time: " + str(ori_time) + '\n' )


for i in range(n):
    for item in collection.find({"value": random.randint(0, 5000000)}):
        print(str(i + 1) + '/' + str(n))
        if len(sys.argv) > 1:
            f_out(str(i + 1) + '/' + str(n) + '\n')
        ori_time = get_ms()
        print(ori_time, '+', item)
        if len(sys.argv) > 1:
            f_out(ori_time, '+', item + '\n')

print("done")
if len(sys.argv) > 1:
    f_out("done\n")

ori_time = get_ms()
print("end_time: ",ori_time)
if len(sys.argv) > 1:
    f_out("end_time: " + str(ori_time) + '\n')
    f_out.close()