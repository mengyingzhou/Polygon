import time

class CpuUsage:
    def readCpuInfo(self):
        f = open('/proc/stat')
        info = f.readlines()
        f.close()
        
        for line in info:
            line = line.lstrip()
            counters = line.split()
            global len
            if len(counters) < 5:
                continue
               
            if counters[0].startswith('cpu'):
                break
            
        total = 0 
        
        for i in range(1, len(counters)):
            total = total + float(counters[i])
            
        idle = float(counters[4])
        
        return {'total':total, 'idle':idle}
    
    def calcCpuUsage(self, counters1, counters2):
        idle = counters2['idle'] - counters1['idle']
        total = counters2['total'] - counters1['total']
        return 100 - (idle * 100 / total)
    
    def getCpuUsage(self):
        counters1 = self.readCpuInfo()
        time.sleep(0.2)
        counters2 = self.readCpuInfo()
        
        return self.calcCpuUsage(counters1, counters2)

            
        