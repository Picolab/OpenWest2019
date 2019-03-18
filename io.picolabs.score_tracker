ruleset io.picolabs.score_tracker {
  meta {
    use module io.picolabs.cookies alias cookies
    shares __testing, totalPoints, getScores, nameTaken, cookieFromRecoveryCode, infoFromName, currentRanks, nameFromScoreTracker, getScoreTracker, getPointsArr, getRank, currentStanding
    provides totalPoints, getScores, nameTaken, cookieFromRecoveryCode, infoFromName, currentRanks, nameFromScoreTracker, getScoreTracker, getPointsArr, currentStanding
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" },
      { "name": "getScores" },
      { "name": "currentRanks" },
      { "name": "getRank", "args": ["scoreTracker"] },
      { "name": "currentStanding", "args": ["scoreTracker"] },
      { "name": "totalPoints", "args": ["scoreTracker"] },
      {"name": "getPointsArr", "args": ["scoreTracker"] },
      { "name": "nameFromScoreTracker", "args": ["scoreTracker"] },
      { "name": "nameTaken", "args": ["first", "last"] },
      { "name": "infoFromName", "args": ["first", "last"] },
      { "name": "cookieFromRecoveryCode", "args": ["recoveryCode", "first", "last"] }
      ] , "events":
      [ { "domain": "score", "type": "new_points", "attrs": ["points", "descr"] }
      , { "domain": "score", "type": "new_participant", "attrs": ["first", "last", "phoneNum"] },
      { "domain": "score", "type": "recovery_needed", "attrs": ["recoveryCode", "first", "last"] }
      ]
    }
    
    currentStanding = function(scoreTracker) {
      nameFromScoreTracker(scoreTracker).put(getRank(scoreTracker)).put("points", totalPoints(scoreTracker));
    }
    
    getScores = function() {
      ent:scores.defaultsTo({})
    }
    
    //returns an array of maps, with the maps being ordered such that first place is first in the array. There is no deterministic order in case of ties, except that those of the same point value will be grouped together
    currentRanks = function() {
      //first, calculate the points for each participant
      points = getScores().map(function(obj, scoreTracker) {
        {
          "first": obj{"first"},
          "last": obj{"last"},
          "points": totalPoints(scoreTracker)
        }
      });
      //sort the participants by points
      points.values().sort(function(a, b) {
        a{"points"} < b {"points"} => 1 |
          a{"points"} == b {"points"} => 0 | -1
      })
    }
    
    getRank = function(scoreTracker) {
      name = nameFromScoreTracker(scoreTracker);
      ranks = currentRanks();
      map = name.put("points", totalPoints(scoreTracker));
      indexInRanks = ranks.index(map);
      peersArr = ranks.filter(function(x) { x{"points"} == map{"points"} });
      indexInPeers = peersArr.index(map);
      rank = (indexInRanks - indexInPeers) + 1;
      peersArr.length() > 1 => { "tied" : true, "rank" : rank } | { "tied" : false, "rank" : rank }
    }
    
    totalPoints = function(scoreTracker) {
      tracker = event:attr("scoreTracker") => event:attr("scoreTracker") | scoreTracker;
      scores = getScores(){[tracker, "pointsArr"]};
      scores => scores.reduce(function(counter, current){
        counter + current{"points"}
      }, 0) | -1 //-1 means this user is not registered...
    }
    
    nameTaken = function(first, last) {
      getScores().values().reduce(function(counter, current){
        counter == true => true | (current{"first"} == first && current{"last"} == last => true | false)
      }, false)
    }
    
    nameFromScoreTracker = function(scoreTracker) {
      info = getScores(){[scoreTracker]};
      {
        "first": info{"first"},
        "last": info{"last"}
      }
    }
    
    cookieFromRecoveryCode = function(recoveryCode, first, last) {
      scores = getScores();
      scores.keys().reduce(function(counter, cookieUUID){
        currentRecoveryCode = scores{[cookieUUID, "recoveryCode"]};
        currentFirst = scores{[cookieUUID, "first"]};
        currentLast = scores{[cookieUUID, "last"]};
        counter => counter | ((currentRecoveryCode == recoveryCode) && (first == currentFirst) && (last == currentLast) => cookieUUID | null)
      }, null)
    }
    
    getPointsArr = function(scoreTracker) {
      getScores(){[scoreTracker, "pointsArr"]}.defaultsTo([])
    }
    
    infoFromName = function(first, last) {
      getScores().values().reduce(function(counter, current){
        counter => counter | (current{"first"} == first && current{"last"} == last => current | false)
      }, null)
    }
    
    getScoreTracker = function() {
      cookieTracker = cookies:cookies(){"scoreTracker"};
      (cookieTracker) => cookieTracker | event:attr("scoreTracker")
    }
    
    app = { "name":"Score Tracker", "version":"0.1" };
    
    DID_Policy = {
        "name": "only allow score events",
        "event": {
            "allow": [
                { "domain": "score" }
            ]
        }
    }
  }
  
  /* ent:scores
    {
      <someUUID> :  {                     // the UUID is meant to be stored in a cookie on someone's device under the key, "scoreTracker"
        first: <string>,
        last: <string>,
        phoneNum: <string>,
        recoveryCode: <random:uuid()>,    // accidentally cleared your cookies? talk to an admin to get your recovery code
        pointsArr: [{
          "timestamp": <time:now()>,
          "points": <number>,
          "descr": <string>},             //a description of the points earned
        ...]
      },
      ...
    }
  */
  
  rule init {
    select when wrangler ruleset_added where rids >< meta:rid
    every{
      engine:newPolicy(DID_Policy) setting(registered_policy)
      engine:newChannel(name="scoreTracker", type="scoreEvents", policy_id = registered_policy{"id"})
    }
  }
  
  rule discovery {
    select when manifold apps
    send_directive("app discovered...",
                            {
                              "app": app,
                              "iconURL": "https://image.flaticon.com/icons/svg/1162/1162481.svg"
                            } );
  }
  
  rule addPoints {
    select when score new_points
    pre {
      scoreTracker = getScoreTracker()
      time = time:now()
      points = event:attr("points").as("Number") //cast into a number just in case the attribute arrives as a string
      descr = event:attr("descr")
      newEntry = {
        "timestamp": time,
        "points": points,
        "descr": descr
      }
    }
    if not points.isnull() && descr && scoreTracker then
      noop()
    fired {
      ent:scores{[scoreTracker, "pointsArr"]} := getScores(){[scoreTracker, "pointsArr"]}.append([newEntry]);
      raise score event "points_added"
        attributes newEntry.put("scoreTracker", scoreTracker)
    } else {
      raise score event "missing_attributes"
        attributes event:attrs
    }
  }
  
  rule reportMissing {
    select when score missing_attributes
    send_directive("Missing event attributes")
  }
  
  rule createCookie {
    select when score new_participant
    pre {
      first = event:attr("first")
      last = event:attr("last")
      phoneNum = event:attr("phoneNum")
      id = random:uuid()
      taken = nameTaken(first, last)
      recoveryCode = random:integer(10000).as("String")
    }
    if first && last && phoneNum && not taken then
      send_directive("_cookie", {"cookie": <<scoreTracker=#{id}; Path=/>>})
    fired {
      ent:scores{[id]} := {
        "first": first,
        "last": last,
        "phoneNum": phoneNum,
        "recoveryCode": recoveryCode,
        "pointsArr": []
      }
    } else {
      raise score event "name_taken"
        attributes event:attrs if taken
    }
  }
  
  rule nameTaken {
    select when score name_taken
    send_directive("Name already taken!")
  }
  
  rule recoverCookie {
    select when score recovery_needed
    pre {
      recoveryCode = event:attr("recoveryCode")
      first = event:attr("first")
      last = event:attr("last")
      cookie = cookieFromRecoveryCode(recoveryCode, first, last)
    }
    if cookie then
      send_directive("_cookie", {"cookie": <<scoreTracker=#{cookie}; Path=/>>})
  }
}
