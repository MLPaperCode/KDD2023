from time import sleep
import copy
import json
import requests

class SolverResponse(object):
    
    class AttributeSolution(object):
        
        def __init__(self, obj):
            self.obj = obj

        def __getattr__(self, key):
            if key in self.obj:
                return self.obj.get(key)
            else:
                raise AttributeError(key)

        def keys(self):
            return self.obj.keys()

    def __init__(self, response):
        solutions = response.json()[u'qubo_solution'][u'solutions']
        self.response = response
        self._solution_histogram = []
        for i, d in enumerate(solutions):
            if i == solutions.index(d):
                self._solution_histogram.append(copy.deepcopy(d))
            else:
                for s in self._solution_histogram:
                    if s[u'configuration'] == d[u'configuration']:
                        s[u'frequency'] += 1
                        break
        self._solution_histogram = sorted([self.AttributeSolution(d) for d in self._solution_histogram], key=lambda x: x.energy)

class DA3Solver:
    
    def __init__(self, running_time, rest_url, access_key, version, proxies, headers):
        self.rest_url = rest_url
        self.access_key = access_key
        self.version = version
        self.proxies = proxies
        self.rest_headers = headers
        self.params = {}
        self.params['time_limit_sec'] = running_time
        self.total_elapsed_time = 0
        
    def minimize(self, request):
        request.update({"fujitsuDA3": self.params})
        request_json = json.dumps(request)
        headers = self.rest_headers
        headers['X-Api-Key'] = self.access_key        
        post_status = requests.post(self.rest_url + '/' + self.version + '/async/qubo/solve', request_json, headers=headers, proxies=self.proxies)        
        jobid = post_status.json()['job_id']
        response = requests.get(self.rest_url + '/' + self.version + '/async/jobs/result/' + jobid, headers=headers, proxies=self.proxies)
        j = response.json()
        while j['status'] in ['Running', 'Waiting']:  
            sleep(10)
            response = requests.get(self.rest_url + '/' + self.version + '/async/jobs/result/' + jobid, headers=headers, proxies=self.proxies)
            j = response.json()
        delete_status = requests.delete(self.rest_url + '/' + self.version + '/async/jobs/result/' + jobid, headers=headers, proxies=self.proxies)
        if post_status.ok:
            if j[u'qubo_solution'].get(u'timing'):
                self.total_elapsed_time = j[u'qubo_solution'][u'timing'][u'total_elapsed_time']
            if j[u'qubo_solution'][u'result_status']:
                return SolverResponse(response)
            raise RuntimeError('result_status is false.')
        else:
            raise RuntimeError(response.text)