# Copyright (c) 2012, Ryan Gomba
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are those
# of the authors and should not be interpreted as representing official policies,
# either expressed or implied, of the FreeBSD Project.

import math
from pprint import pprint

################################################################################
# POINT
################################################################################

class Point:

    def __init__(self, x, z):

        self.x = x
        self.z = z
        self.cd = None              # core distance
        self.rd = None              # reachability distance
        self.processed = False      # has this point been processed?

    # --------------------------------------------------------------------------
    # calculate the distance between any two points on earth
    # --------------------------------------------------------------------------

    def distance(self, point):
        return (self.x - point.x)**2 + (self.z - point.z)**2


    def __repr__(self):
        return '(%f, %f, %s, %s, %s)' % (self.x, self.z, self.cd, self.rd, self.processed)

################################################################################
# CLUSTER
################################################################################

class Cluster:

    def __init__(self, points):

        self.points = points

    # --------------------------------------------------------------------------
    # calculate the centroid for the cluster
    # --------------------------------------------------------------------------

    def centroid(self):

        return Point(sum([p.x for p in self.points])/len(self.points),
            sum([p.z for p in self.points])/len(self.points))

    # --------------------------------------------------------------------------
    # calculate the region (centroid, bounding radius) for the cluster
    # --------------------------------------------------------------------------

    def region(self):

        centroid = self.centroid()
        radius = reduce(lambda r, p: max(r, p.distance(centroid)), self.points)
        return centroid, radius


################################################################################
# OPTICS
################################################################################

class Optics:

    def __init__(self, points, max_radius, min_cluster_size):

        self.points = points
        self.max_radius = max_radius**2             # maximum radius to consider
        self.min_cluster_size = min_cluster_size    # minimum points in cluster

    # --------------------------------------------------------------------------
    # get ready for a clustering run
    # --------------------------------------------------------------------------

    def _setup(self):

        for p in self.points:
            p.rd = None
            p.processed = False
        self.unprocessed = [p for p in self.points]
        self.ordered = []

    # --------------------------------------------------------------------------
    # distance from a point to its nth neighbor (n = min_cluser_size)
    # --------------------------------------------------------------------------

    def _core_distance(self, point, neighbors):

        if point.cd is not None: return point.cd
        if len(neighbors) >= self.min_cluster_size - 1:
            sorted_neighbors = sorted([n.distance(point) for n in neighbors])
            point.cd = sorted_neighbors[self.min_cluster_size - 2]
            return point.cd

    # --------------------------------------------------------------------------
    # neighbors for a point within max_radius
    # --------------------------------------------------------------------------

    def _neighbors(self, point):

        return [p for p in self.points if p is not point and
            p.distance(point) <= self.max_radius]

    # --------------------------------------------------------------------------
    # mark a point as processed
    # --------------------------------------------------------------------------

    def _processed(self, point):

        point.processed = True
        self.unprocessed.remove(point)
        self.ordered.append(point)

    # --------------------------------------------------------------------------
    # update seeds if a smaller reachability distance is found
    # --------------------------------------------------------------------------

    def _update(self, neighbors, point, seeds):

        # for each of point's unprocessed neighbors n...

        for n in [n for n in neighbors if not n.processed]:

            # find new reachability distance new_rd
            # if rd is null, keep new_rd and add n to the seed list
            # otherwise if new_rd < old rd, update rd

            new_rd = max(point.cd, point.distance(n))
            if n.rd is None:
                n.rd = new_rd
                seeds.append(n)
            elif new_rd < n.rd:
                n.rd = new_rd

    # --------------------------------------------------------------------------
    # run the OPTICS algorithm
    # --------------------------------------------------------------------------

    def run(self):

        self._setup()

        # for each unprocessed point (p)...

        while self.unprocessed:
            point = self.unprocessed[0]

            # mark p as processed
            # find p's neighbors

            self._processed(point)
            point_neighbors = self._neighbors(point)

            # if p has a core_distance, i.e has min_cluster_size - 1 neighbors

            if self._core_distance(point, point_neighbors) is not None:

                # update reachability_distance for each unprocessed neighbor

                seeds = []
                self._update(point_neighbors, point, seeds)

                # as long as we have unprocessed neighbors...

                while(seeds):

                    # find the neighbor n with smallest reachability distance

                    seeds.sort(key=lambda n: n.rd)
                    n = seeds.pop(0)

                    # mark n as processed
                    # find n's neighbors

                    self._processed(n)
                    n_neighbors = self._neighbors(n)

                    # if p has a core_distance...

                    if self._core_distance(n, n_neighbors) is not None:

                        # update reachability_distance for each of n's neighbors

                        self._update(n_neighbors, n, seeds)

        # when all points have been processed
        # return the ordered list

        return self.ordered

    # --------------------------------------------------------------------------

    def cluster(self, cluster_threshold):

        clusters = []
        separators = []

        for i in range(len(self.ordered)):
            this_i = i
            next_i = i + 1
            this_p = self.ordered[i]
            this_rd = this_p.rd if this_p.rd else float('infinity')

            # use an upper limit to separate the clusters

            if this_rd > cluster_threshold:
                separators.append(this_i)

        separators.append(len(self.ordered))
        print "~~~~~~~~~~~~~~~"
        pprint(separators)
        print "~~~~~~~~~~~~~~~"

        for i in range(len(separators) - 1):
            start = separators[i]
            end = separators[i + 1]
            if end - start >= self.min_cluster_size:
                clusters.append(Cluster(self.ordered[start:end]))
        #pprint(clusters)
        pprint(self.ordered)
        return clusters

# LOAD SOME POINTS

points = [
    Point(10, 10), # cluster #1
    Point(11, 11), # cluster #1
    Point(12, 12), # cluster #1
    Point(20, 20), # cluster #2
    Point(21, 21), # cluster #2
    Point(22, 22), # cluster #2
]
print points
print "##########################################################"

optics = Optics(points, 5, 2) # 100m radius for neighbor consideration, cluster size >= 2 points
optics.run()                    # run the algorithm
clusters = optics.cluster(5)   # 50m threshold for clustering

for cluster in clusters:
    print cluster.points
