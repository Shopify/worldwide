{ :kw => { :i18n => { :plural => { :keys => [:zero, :one, :two, :few, :many, :other], :rule => lambda { |n| n = n.respond_to?(:abs) ? n.abs : ((m = n.to_s)[0] == "-" ? m[1,m.length] : m); n.to_f == 0 ? :zero : n.to_f == 1 ? :one : ([2, 22, 42, 62, 82].include?(n.to_f % 100) || (n.to_f % 1000 == 0 && ([40000, 60000, 80000].include?(n.to_f % 100000) || (((n.to_f % 100000) % 1).zero? && (1000..20000).include?(n.to_f % 100000)))) || (n.to_f != 0 && n.to_f % 1000000 == 100000)) ? :two : [3, 23, 43, 63, 83].include?(n.to_f % 100) ? :few : (n.to_f != 1 && [1, 21, 41, 61, 81].include?(n.to_f % 100)) ? :many : :other } } } } }