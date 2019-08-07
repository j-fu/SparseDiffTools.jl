using LightGraphs
using DataStructures

"""
        color_graph(g::LightGraphs.AbstractGraphs, :: AcyclicColoring)

Returns a coloring vector following the acyclic coloring rules (1) the coloring 
corresponds to a distance-1 coloring, and (2) vertices in every cycle of the 
graph are assigned at least three distinct colors. This variant of coloring is 
called acyclic since every subgraph induced by vertices assigned any two colors
is a collection of trees—and hence is acyclic.
"""
function color_graph(g::LightGraphs.AbstractGraphs, ::AcyclicColoring)
    
    color = zeros(Int, nv(g))
    forbiddenColors = zeros(Int, nv(g))

    set = DisjointSets{LightGraphs.Edge}([])

    firstVisitToTree = Array{Tuple{Int, Int}, 1}(undef, ne(g))
    firstNeighbor = Array{Tuple{Int, Int}, 1}(undef, nv(g))

    for v in vertices(g)
        #enforces the first condition of acyclic coloring
        for w in outneighbors(g, v)
            if color[w] != 0
                forbiddenColors[color[w]] = v
            end
        end
        #enforces the second condition of acyclic coloring
        for w in outneighbors(g, v)
            if color[w] != 0 #colored neighbor
                for x in outneighbors(g, w)
                    if color[x] != 0 #colored x
                        if forbiddenColors[color[x]] != v
                            prevent_cycle(v, w, x, g, color, forbiddenColors, firstVisitToTree, set)
                        end
                    end
                end
            end
        end

        color[v] = min_index(forbiddenColors, v)

        #grow star for every edge connecting colored vertices v and w
        for w in outneighbors(g, v)
            if color[w] != 0
                grow_star(v, w, g, firstNeighbor, set)
            end
        end

        #merge the newly formed stars into existing trees if possible
        for w in outneighbors(g, v)
            if color[w] != 0
                for x in outneighbors(g, w)
                    if color[x] != 0 && x != v
                        if color[x] == color[v]
                            mergeTrees(v, w, x, g, set)
                        end
                    end
                end
            end
        end 
    end

    return color
end

"""
        prevent_cycle()

"""
function prevent_cycle(v::Integer,
                       w::Integer, 
                       x::Integer,
                       g,
                       color, 
                       forbiddenColors::AbstractVector{<:Integer},
                       firstVisitToTree,
                       set)
    
    edge = find_edge(g, w, x)
    e = find_root(set, edge)
    p, q = firstVisitToTree[edge_index(g, e)]
    if p != v
        firstVisitToTree[edge_index(g, e)] = (v, w)
    else if q != w
        forbiddenColors[color[x]] = v
    end
end

"""
        min_index(forbiddenColors::AbstractVector{<:Integer}, v::Integer)

Returns min{i > 0 such that forbiddenColors[i] != v}
"""            
function min_index(forbiddenColors, v)
    for i = 1:length(forbiddenColors)
        if forbiddenColors[i] != v
            return i
        end
    end
end

function grow_star(v::Integer,
                  w::Integer,
                  g,
                  firstNeighbor,
                  set)
    edge = find_edge(g, v, w)
    push!(set, edge)
    p, q = firstNeighbor[color[w]]
    if p != v
        firstNeighbor[color[w]] = (v, w)
    else
        edge1 = find_edge(g, v, w)
        edge2 = find_edge(g, p, q)
        e1 = find_root(set, edge1)
        e2 = find_root(set, edge2)
        union!(set, e1, e2)
    end
end

function mergeTrees(v::Integer,
                    w::Integer, 
                    x::Integer,
                    g,
                    set)
    edge1 = find_edge(g, v, w)
    edge2 = find_edge(g, w, x)
    e1 = find_root(set, edge1)
    e2 = find_root(set, edge2)
    if (e1 != e2)
        union!(set, e1, e2)
    end
end

function find_edge(g, v, w)
    for e in edges(g)
        if (src(e) == v && dst(e) == w)
            return e
        end
    end
    throw(error("$v and $w are not connected in graph g"))
end

function edge_index(g, e)
    edge_list = collect(edges(g))
    for i in 1:length(edge_list)
        if edge_list[i] == e
            return i
        end
    end
    return -1
end