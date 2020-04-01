Optics, Cluster = require "Optics"

points = {{x=10,z=10}, {x=11, z=11}, {x=12,z=12}, {x=20,z=20}, {x=21,z=21}, {x=22,z=22}}
oo = Optics.new(points, 5, 2)
oo:Run()
clusters = oo:Clusterize(5)


for k,v in pairs(clusters) do
	v:PrettyPrint()
end

