ruleset uta_time {
  meta {
    shares __testing, dayOfWeek, dayEquals, timeConvert
    provides timeConvert, timeCompare, gtfsTimeCompare, stampConvert, minDiff, dateCompare, dayOfWeek, dayEquals
    
    use module uta_math alias math
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      , { "name": "dayOfWeek" }
      , { "name": "dayEquals" }
      , { "name": "timeConvert" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    timeConvert = function(tString = "13:28:12") {
      wocol = tString.extract(re#[0-9]#g).join("") + "Z";
      
      toRet =time:add((wocol.length() == 6) => "0"+wocol | wocol, { "hours" : 6 });
      
      toRet;
    }
    
    timeCompare = function(time1, time2) {
      (stampConvert(time1) > stampConvert(time2)) => true | false;
    }
    
    dayEquals = function(time1, time2) {
      year1 = time1.substr(0,4);
      month1 = time1.substr(5,2);
      day1 = time1.substr(8,2);
      
      year2 = time2.substr(0,4);
      month2 = time2.substr(5,2);
      day2 = time2.substr(8,2);
      
      year1.as("Number") * 365 + month1.as("Number") * 31 + day1.as("Number") ==  year2.as("Number") * 365 + month2.as("Number") * 31 + day2.as("Number")
      
    }
    
    gtfsTimeCompare = function(t1, t2) {
      time1 = t1.extract(re#[0-9]#g).join("").as("Number");
      time2 = t2.extract(re#[0-9]#g).join("").as("Number");
      (time1 > time2) => true | false;
    }
    
    stampConvert = function(toConv = time:now()) {
      toConv.substr(11,12).extract(re#[0-9|\.]#g).join("").as("Number");
    }
    
    minDiff = function(time) {
      h1 = time.substr(11,2).as("Number");
      h2 = time:now().substr(11,2).as("Number");
      m1 = time.substr(14,2).as("Number");
      m2 = time:now().substr(14,2).as("Number");
      (h1 - h2) * 60 + (m1 - m2)
    }
    
    dateCompare = function(start_date, end_date) {
      start_year = start_date.substr(0,4).as("Number");
      start_month = start_date.substr(4,2).as("Number");
      start_day = start_date.substr(6,2).as("Number");
      start_number = start_year * 365 + start_month * 31 + start_day;
      
      end_year = end_date.substr(0,4).as("Number");
      end_month = end_date.substr(4,2).as("Number");
      end_day = end_date.substr(6,2).as("Number");
      end_number = end_year * 365 + end_month * 31 + end_day;
      
      date = time:strftime(time:add(time:now(), { "hours" : -6 }),"%F");
      year = date.substr(0,4).as("Number");
      month = date.substr(5,2).as("Number");
      day = date.substr(8,2).as("Number");
      number = year * 365 + month * 31 + day;
      
      (start_number <= number && end_number >= number) => true | false
    }
    
    dayOfWeek = function() {
      day_array = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];
      date = time:strftime(time:add(time:now(), { "hours" : -6 }),"%F");
      century = date.substr(0,2).as("Number");
      m = date.substr(5,2).as("Number");
      decade = ((m < 3) => (date.substr(2,2).as("Number") - 1) | (date.substr(2,2).as("Number")));
      month = (m < 3) => m + 10 | m - 2;
      day = date.substr(8,2).as("Number");
      //f = k + [(13*m-1)/5] + D + [D/4] + [C/4] - 2*C.
      f = day + math:floor((13*month-1)/5) + decade + math:floor(decade/4) + math:floor(century/4) - 2*century;
      index = math:modulusCalendar(f);
      day_array[index];
    }
    
  }
}
