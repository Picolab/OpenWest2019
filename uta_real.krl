ruleset uta_real {
  meta {
    shares __testing, loadDirectory, initializeFile, serviceValidToday, exceptionType1, viewFile, times, cached, getTimes, businfo
    provides getTimes
    
    use module uta_time
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      , { "name": "loadDirectory" }
      , { "name": "businfo" }
      , { "name": "viewFile", "args": [ "file" ] }
      , { "name": "serviceValidToday", "args": [ "id" ] }
      , { "name": "initializeFile", "args": [ "file" ] }
      , { "name": "getTimes", "args": [ "code" ] }
      , { "name": "cached" }
      ] , "events":
      [ { "domain": "uta", "type": "init_all" }
      , { "domain": "uta", "type": "init", "attrs": [ "filename" ] }
      , { "domain": "uta", "type": "get_times", "attrs": [ "stop_code" ] }
      , { "domain": "uta", "type": "delete_cache" }
      , { "domain": "delete", "type": "businfo" }
      ]
    }
    
    businfo = function() {
      ent:businfo
    }
    
    viewFile = function(file) {
      ent:businfo{file}
    }
    
    loadDirectory = function() {
      dir = http:get(<<https://raw.githubusercontent.com/KandareJ/UTA/master/directory.txt>>){"content"}.split(re#\r?\n#);
      dir.splice(dir.length() - 1, 1);
      //["calendar", "calendar_dates", "trips"]
    }
    
    initializeFile = function(file) {
      
      resp = http:get(<<https://raw.githubusercontent.com/KandareJ/UTA/master/#{file}.txt>>){"content"}.split(re#\r?\n#);
      header = resp[0].split(re#,#);
      body = resp.splice(0,1).splice(resp.length()-2,1);
      
      body.map(function(x){
        params = x.split(re#,#);
        myMap = [header, params].pairwise(function(x,y) {
          {}.put(x,y);
        });
        myMap.reduce(function(a,b){
          a.put(b.keys()[0], b.values()[0]);
        }, {})
      });
      
    }
    
    busTimes = function(code) {
      uta = uta1(code);
      routeList = getRoutes(uta{"routes_array"});
      prettyRoutes = routeList.map(function(x) {
        temp = ent:businfo{"routes"}.filter(function(y){
          y["route_id"] == x
        }).head();
        temp["short_name"] + " - " + temp["long_name"]
      });
      serviceIDList = getServiceIDs(routeList);
      routeList.klog("Routes to be KLOGGED");
      serviceIDList.klog("Service ID's to be KLOGGED");
      pairwised = [routeList, serviceIDList].pairwise(function(x,y){{}.put(x,y)}).reduce(function(a,b){a.put(b)}).klog("PAIRWISED");
      filterServiceIDs(pairwised).klog("FilteredPairwised");
      
      routesArray = filterServiceIDs(pairwised).map(function(v,k) {
        v.map(function(x) {
          times(code, k, x);
        }).head()
      });
      routesArray.keys().klog("After filter");
      
      all = uta.put("routes_array", routesArray);
      newAll = [prettyRoutes, all["routes_array"].values()].pairwise(function(x,y){{}.put(x,y)}).reduce(function(a,b){a.put(b)}).klog("PAIRWISED").head();
      all["routes_array"] = newAll;/*.map(function(x) {
        x.sort(uta_time:gtfsTimeCompare).filter(function(y) {
          uta_time:timeCompare(uta_time:timeConvert(y), time:now());
        });
      }).map(function(x){ x.append(uta_time:minDiff(uta_time:timeConvert(x[0]))) });*/
      all
    }
    
    getTimes = function(code) {
      all = busTimes(code);
      all["routes_array"] = all["routes_array"].map(function(x) {
        x.sort(uta_time:gtfsTimeCompare).filter(function(y) {
          uta_time:timeCompare(uta_time:timeConvert(y), time:now());
        });
      }).map(function(x){ x.append(uta_time:minDiff(uta_time:timeConvert(x[0]))) });
      all
    }
    
    getTimes2 = function(all) {
      all["routes_array"] = all["routes_array"].map(function(x) {
        x.sort(uta_time:gtfsTimeCompare).filter(function(y) {
          uta_time:timeCompare(uta_time:timeConvert(y), time:add(time:now(), {"minutes": -3}));
        });
      }).map(function(x){ x.append(uta_time:minDiff(uta_time:timeConvert(x[0]))) });
      all
    }
    
    stopCode = function(code) {
      code.klog("Value:");
      temp = ent:store.filter(function(x) { x{"Code"} == code })[0];
      temp["RoutesArray"] = temp["RoutesArray"].map(function(x) {
        x.filter(function(y) {
          uta_time:timeCompare(timeConvert(y), time:now());
        });
        
        
      }).map(function(x){ x.append(uta_time:minDiff(uta_time:timeConvert(x[0]))) });
      temp
    }
    
    //and ends here ------------------------------------------------------------------------------------------------------------------
    
    times = function(stop_code, route_id, service_id) {
      file = "stop_times_" + service_id;
      ent:businfo{file}.filter(function(x){
        x{"stop_code"} == stop_code && x{"route_id"} == route_id
      }).map(function(x) {
        x{"time"}
      })
    }
    
    uta1 = function(code) {
      ent:businfo{"UTA1"}.filter(function(x){
        x{"stop_code"} == code
      }).head();
    }
    
    getRoutes = function(routesArray) {
      routesArray.split(re#-#);
    }
    
    getServiceIDs = function(routeList) {
      routeList.map(function(x) {
        ent:businfo{"trips"}.filter(function(y) {
          y{"route_id"} == x;
        }).map(function(z){z{"service_id"}}).sort("numeric").reduce(function(a,b) {
          (a >< b) => a | a.append(b);
        })
      })
    }
    
    getRouteInfo = function (routeList) {
      routeList.map(function(x) {
        ent:businfo{"routes"}.filter(function(y) {
          y{"route_id"} == x
        })
      })
    }
  
    filterServiceIDs = function(routesMap) {
      routesMap.map(function(v, k) {
        v.filter(function(x) {
          serviceValidToday(x)
        });
        
      });
    }
    
    serviceValidToday = function(id) {
      serviceInfo = ent:businfo{"calendar"}.filter(function(x) {
        x{"service_id"} == id
      }).head();
      test1 = uta_time:dateCompare(serviceInfo["start_date"], serviceInfo["end_date"]);
      test2 = (serviceInfo[uta_time:dayOfWeek()] == "1");
      (test1 && test2) => exceptionType2(id) | exceptionType1(id);
    }
    
    exceptionType1 = function(id) {
      today = time:strftime(time:add(time:now(), { "hours" : -6 }),"%F").extract(re#([0-9]+)#g).join("");
      temp = ent:businfo{"calendar_dates"}.filter(function(x){
        (x{"service_id"} == id && x{"date"} == today)
      }).head();
      (temp{"exception_type"} == "1") => true | false
    }
    
    exceptionType2 = function(id) {
      today = time:strftime(time:add(time:now(), { "hours" : -6 }),"%F").extract(re#([0-9]+)#g).join("");
      temp = ent:businfo{"calendar_dates"}.filter(function(x){
        (x{"service_id"} == id && x{"date"} == today)
      }).head();
      (temp{"exception_type"} == "2") => false | true
    }
    
    cached = function() {
      ent:cached
    }
    
    DID_Policy = {
        "name": "only allow uta events",
        "event": {
            "allow": [
                { "domain": "uta", "type": "get_times"}
            ]
        }
    }
    
    
  }
  
  rule init {
    select when wrangler ruleset_added where rids >< meta:rid
    every{
      engine:newPolicy(DID_Policy) setting(registered_policy)
      engine:newChannel(name="uta", type="uta", policy_id = registered_policy{"id"})
    }
  }
  
  
  rule initialize_uta_all {
    select when uta init_all
    
    foreach loadDirectory() setting (x, i)
    send_directive("name", { "fileNameIn" : x.klog("x"), "index" : i.klog("i") })
    
    always {
      raise uta event "init"
      attributes { "filename" : x }
    }
    
  }
  
  rule initialize_uta_file {
    select when uta init
    
    pre {
      fname = event:attr("filename").klog("filename");
      arr = initializeFile(fname) 
    }
    always {
      ent:businfo := ent:businfo.defaultsTo({}).put(fname, arr);
    }
  }
  
  rule uta_times {
    select when uta get_times
    pre {
      code = event:attr("stop_code");
    }
    
    if ((not ent:cached[code].isnull()) && uta_time:dayEquals(time:now(), ent:cached[code]["timestamp"])) then
    send_directive("times", getTimes2(ent:cached[code]["bus"]));
    
    notfired {
      raise uta event "cache_times"
      attributes {
        "stop_code" : code
      }
    }
    
  }
  
  rule uta_cache {
    select when uta cache_times
    pre {
      code = event:attr("stop_code");
      times=busTimes(code);
      res = getTimes2(times)
      cache = {}.put("timestamp", time:now()).put("bus", times);
    }
    send_directive("times", res);
    
    always {
      ent:cached := ent:cached.defaultsTo({}).put(code, cache);
      raise uta event "clear_cache"
    }
  }
  
  rule clear_cache {
    select when uta clear_cache
    always {
      ent:cached := ent:cached.filter(function(v, k){
        uta_time:dayEquals(time:now(), v["timestamp"])
      })
    }
  }
  
  rule delete_cache {
    select when uta delete_cache
    always {
      ent:cached := {}
    }
  }
  
  rule delete_businfo {
    select when delete businfo
    always {
      ent:businfo := {}
    }
  }

}
