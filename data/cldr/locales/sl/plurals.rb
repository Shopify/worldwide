{ :sl => { :i18n => { :plural => { :keys => [:one, :two, :few, :other], :rule => lambda { |n| n = n.respond_to?(:abs) ? n.abs : ((m = n.to_s)[0] == "-" ? m[1,m.length] : m); (((v = n.to_s.split(".")[1]) ? v.length : 0) == 0 && n.to_i % 100 == 1) ? :one : (((v = n.to_s.split(".")[1]) ? v.length : 0) == 0 && n.to_i % 100 == 2) ? :two : ((((v = n.to_s.split(".")[1]) ? v.length : 0) == 0 && (3..4).include?(n.to_i % 100)) || ((v = n.to_s.split(".")[1]) ? v.length : 0) != 0) ? :few : :other } } } } }