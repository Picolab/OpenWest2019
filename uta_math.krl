ruleset uta_math {
  meta {
    shares __testing
    provides modulusCalendar, floor, remainder, round
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    
    
    modulusCalendar = function(num) {
      (num % 7 >= 0) => num % 7 | 7 + num % 7;
    }
    
    floor = function(num) {
        num.as("String").extract(re#(-?\d*)[.]?.*#)[0].as("Number")
    }
    
    remainder = function(num) {
        (num.as("Number") == 0) => 0 |
        (num.as("Number") > 0) => ("0." + num.as("String").extract(re#[.](\d*)#)[0]).as("Number") | ("-0." + num.as("String").extract(re#[.](\d*)#)[0]).as("Number") 
    }
    
    round = function(num) {
      (remainder(num) >= .5) => floor(num) + 1 | floor(num)
    }
    
    
  }
}
