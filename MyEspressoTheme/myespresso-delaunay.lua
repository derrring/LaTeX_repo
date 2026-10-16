-- myespresso-delaunay.lua
-- Delaunay triangulation for the MyEspresso cover ornament.
--
-- Scope: a decorative triangle field, N in the tens, random points in a
-- rectangle. NOT a meshing library. Its two geometric decisions -- which side
-- of a line a point lies on, and whether it lies inside a circumcircle -- are
-- exact (Shewchuk's adaptive predicates, below): a plain floating-point
-- in-circle test, evaluated next to super-triangle vertices ~1e7 times the
-- data's span away, misjudged points often enough that a third of random
-- point sets without the rectangle's corners came out not Delaunay.
--
-- Determinism is a requirement, not a nicety: the same document must rebuild
-- to a byte-identical PDF. Hence the explicit LCG below rather than
-- math.random, whose algorithm differs across Lua 5.3 / 5.4 / LuaJIT.

local M = {}

-- ---------------------------------------------------------------- RNG ----
-- glibc's LCG. Quality is irrelevant here; reproducibility across engines
-- and versions is the whole point.
local function new_rng(seed)
  local state = seed % 2147483648
  return function()
    state = (1103515245 * state + 12345) % 2147483648
    return state / 2147483648
  end
end

-- ---------------------------------------------------------- predicates ----
-- orient(a,b,c) > 0 when a,b,c turn counter-clockwise, < 0 clockwise, 0 on a
-- line. incircle(a,b,c,d) > 0 when d lies strictly inside the circle through
-- a,b,c taken counter-clockwise, < 0 outside, 0 on it. Both return the EXACT
-- sign for any doubles: a floating-point evaluation is accepted when it clears
-- Shewchuk's error bound, and otherwise the determinant is recomputed exactly
-- as an expansion -- a sum of non-overlapping doubles -- built from two_sum and
-- two_product. Lua has no fused multiply-add, so two_product uses Dekker's
-- split. Reference: J. R. Shewchuk, "Adaptive Precision Floating-Point
-- Arithmetic and Fast Robust Geometric Predicates", DCG 18 (1997).
local EPS = 2.0 ^ -53
local CCW_BOUND = (3 + 16 * EPS) * EPS
local ICC_BOUND = (10 + 96 * EPS) * EPS
local SPLITTER = 2.0 ^ 27 + 1

local function two_sum(a, b)
  local x = a + b
  local bv = x - a
  local av = x - bv
  return x, (a - av) + (b - bv)
end

local function split(a)
  local c = SPLITTER * a
  local hi = c - (c - a)
  return hi, a - hi
end

local function two_product(a, b)
  local x = a * b
  local ahi, alo = split(a)
  local bhi, blo = split(b)
  local err = ((x - ahi * bhi) - alo * bhi) - ahi * blo
  return x, alo * blo - err
end

-- e + b for an expansion e, zero components dropped.
local function grow(e, b)
  local h, q = {}, b
  for i = 1, #e do
    local r
    q, r = two_sum(q, e[i])
    if r ~= 0 then h[#h + 1] = r end
  end
  if q ~= 0 or #h == 0 then h[#h + 1] = q end
  return h
end

local function add_product(e, a, b, s)   -- e + s*a*b, s = +1 or -1
  local x, y = two_product(a, b)
  return grow(grow(e, s * y), s * x)
end

local function times(e, f)               -- e * f, both expansions
  local h = { 0 }
  for i = 1, #e do
    for j = 1, #f do h = add_product(h, e[i], f[j], 1) end
  end
  return h
end

local function sum(e, f, s)              -- e + s*f
  for i = 1, #f do e = grow(e, s * f[i]) end
  return e
end

local function sign(e)
  for i = #e, 1, -1 do
    if e[i] ~= 0 then return e[i] > 0 and 1 or -1 end
  end
  return 0
end

local function sgn(x) return x > 0 and 1 or (x < 0 and -1 or 0) end

-- |px py 1; qx qy 1; rx ry 1| as an exact expansion.
local function det3(p, q, r)
  local e = { 0 }
  e = add_product(e, p[1], q[2], 1); e = add_product(e, p[2], q[1], -1)
  e = add_product(e, q[1], r[2], 1); e = add_product(e, q[2], r[1], -1)
  e = add_product(e, r[1], p[2], 1); e = add_product(e, r[2], p[1], -1)
  return e
end

local function orient(a, b, c)
  local detleft = (a[1] - c[1]) * (b[2] - c[2])
  local detright = (a[2] - c[2]) * (b[1] - c[1])
  local det = detleft - detright
  local detsum
  if detleft > 0 then
    if detright <= 0 then return sgn(det) end
    detsum = detleft + detright
  elseif detleft < 0 then
    if detright >= 0 then return sgn(det) end
    detsum = -detleft - detright
  else
    return sgn(det)
  end
  if math.abs(det) >= CCW_BOUND * detsum then return sgn(det) end
  return sign(det3(a, b, c))
end

local function lift(p)                   -- px^2 + py^2, exact
  return add_product(add_product({ 0 }, p[1], p[1], 1), p[2], p[2], 1)
end

local function incircle(a, b, c, d)
  local adx, ady = a[1] - d[1], a[2] - d[2]
  local bdx, bdy = b[1] - d[1], b[2] - d[2]
  local cdx, cdy = c[1] - d[1], c[2] - d[2]
  local bdxcdy, cdxbdy = bdx * cdy, cdx * bdy
  local cdxady, adxcdy = cdx * ady, adx * cdy
  local adxbdy, bdxady = adx * bdy, bdx * ady
  local alift = adx * adx + ady * ady
  local blift = bdx * bdx + bdy * bdy
  local clift = cdx * cdx + cdy * cdy
  local det = alift * (bdxcdy - cdxbdy) + blift * (cdxady - adxcdy)
            + clift * (adxbdy - bdxady)
  local permanent = (math.abs(bdxcdy) + math.abs(cdxbdy)) * alift
                  + (math.abs(cdxady) + math.abs(adxcdy)) * blift
                  + (math.abs(adxbdy) + math.abs(bdxady)) * clift
  if math.abs(det) > ICC_BOUND * permanent then return sgn(det) end
  -- The 4x4 determinant |x y x^2+y^2 1| over a,b,c,d, expanded along its
  -- lift column; it equals the translated 3x3 one above.
  local e = times(lift(a), det3(b, c, d))
  e = sum(e, times(lift(b), det3(a, c, d)), -1)
  e = sum(e, times(lift(c), det3(a, b, d)), 1)
  e = sum(e, times(lift(d), det3(a, b, c)), -1)
  return sign(e)
end

-- d strictly inside the circumcircle of the triangle (a,b,c), either winding.
local function in_circumcircle(a, b, c, d)
  local o = orient(a, b, c)
  return o ~= 0 and o * incircle(a, b, c, d) > 0
end

-- ---------------------------------------------------------- Bowyer-Watson ----
-- pts: array of {x, y}. Returns an array of triangles as index triples into
-- pts. Points are indices so the caller can recover coordinates and so the
-- edge de-duplication below can key on integers.
function M.triangulate(pts)
  local n = #pts
  if n < 3 then return {} end

  -- Super-triangle. "Contains every point" is necessary but nowhere near
  -- sufficient: vertices too close to the data distort the triangles along
  -- the convex hull, and removing the super-triangle at the end then takes
  -- real hull triangles with it. The result is a triangulation that is
  -- locally Delaunay everywhere it exists but has slivers missing along the
  -- edge -- which the empty-circumcircle test cannot see, because every
  -- triangle it does contain is correct. Only the coverage check catches it.
  --
  -- The predicates are exact, so distance costs no precision and K is set by
  -- that failure alone. Measured 2026-10-16 with these predicates, holes per
  -- configuration set (2000 of the production configuration, n=44, 16 x 4.5;
  -- 1000 random 40-point sets without the corners):
  --     K =      1e1        1e2       1e4     1e5     1e7
  --     holes =  1886/435   434/52    8/0     1/0     0/0
  -- The production configuration needs the larger K: its corners and the
  -- points near the rectangle's edges make long, flat hull triangles, whose
  -- circumcircles are the ones that reach the super-vertices.
  local K = 10000000
  local minx, miny = math.huge, math.huge
  local maxx, maxy = -math.huge, -math.huge
  for _, p in ipairs(pts) do
    minx = math.min(minx, p[1]); maxx = math.max(maxx, p[1])
    miny = math.min(miny, p[2]); maxy = math.max(maxy, p[2])
  end
  local dmax = math.max(maxx - minx, maxy - miny)
  local midx, midy = (minx + maxx) / 2, (miny + maxy) / 2
  local work = {}
  for i, p in ipairs(pts) do work[i] = p end
  work[n + 1] = { midx - K * dmax, midy - dmax }
  work[n + 2] = { midx,            midy + K * dmax }
  work[n + 3] = { midx + K * dmax, midy - dmax }

  local tris = { { n + 1, n + 2, n + 3 } }

  for i = 1, n do
    local p = work[i]
    local bad = {}
    local kept = {}
    for _, t in ipairs(tris) do
      if in_circumcircle(work[t[1]], work[t[2]], work[t[3]], p) then
        bad[#bad + 1] = t
      else
        kept[#kept + 1] = t
      end
    end

    -- Cavity boundary: edges belonging to exactly one bad triangle. An edge
    -- shared by two bad triangles is interior to the cavity and must go.
    local count = {}
    local order = {}
    for _, t in ipairs(bad) do
      for k = 1, 3 do
        local u, v = t[k], t[k % 3 + 1]
        local key = (u < v) and (u .. ":" .. v) or (v .. ":" .. u)
        if count[key] then
          count[key] = count[key] + 1
        else
          count[key] = 1
          order[#order + 1] = { key = key, u = u, v = v }
        end
      end
    end
    for _, e in ipairs(order) do
      if count[e.key] == 1 then
        kept[#kept + 1] = { e.u, e.v, i }
      end
    end
    tris = kept
  end

  -- Drop everything touching the super-triangle.
  local out = {}
  for _, t in ipairs(tris) do
    if t[1] <= n and t[2] <= n and t[3] <= n then out[#out + 1] = t end
  end
  return out
end

-- ---------------------------------------------------------------- edges ----
-- Unique undirected edges. Drawing three edges per triangle strokes every
-- interior edge twice, which at low opacity reads as uneven line weight.
function M.edges(tris)
  local seen, out = {}, {}
  for _, t in ipairs(tris) do
    for k = 1, 3 do
      local u, v = t[k], t[k % 3 + 1]
      if u > v then u, v = v, u end
      local key = u .. ":" .. v
      if not seen[key] then
        seen[key] = true
        out[#out + 1] = { u, v }
      end
    end
  end
  return out
end

-- ----------------------------------------------------------------- points ----
-- Four corners plus interior random points, matching the ornament's shape.
function M.points(opts)
  local rnd = new_rng(opts.seed or 1)
  local w = opts.width or 16
  local h = opts.height or 4.5
  local n = opts.n or 44
  local pts = { { 0, 0 }, { w, 0 }, { w, h }, { 0, h } }
  for _ = 5, n do
    pts[#pts + 1] = { rnd() * w, rnd() * h }
  end
  return pts
end

-- ------------------------------------------------------------ invariants ----
-- Oracles that need no reference implementation.

-- Convex hull (monotone chain, exact orient): its corners only, counter-
-- clockwise. Fewer than three when the points do not span a plane.
local function hull_points(pts)
  local p = {}
  for i, q in ipairs(pts) do p[i] = { q[1], q[2] } end
  table.sort(p, function(a, b)
    if a[1] ~= b[1] then return a[1] < b[1] end
    return a[2] < b[2]
  end)
  local function build(src)
    local st = {}
    for _, q in ipairs(src) do
      while #st >= 2 and orient(st[#st - 1], st[#st], q) <= 0 do
        table.remove(st)
      end
      st[#st + 1] = q
    end
    table.remove(st)
    return st
  end
  local rev = {}
  for i = #p, 1, -1 do rev[#rev + 1] = p[i] end
  local lower, upper = build(p), build(rev)
  for _, q in ipairs(upper) do lower[#lower + 1] = q end
  return lower
end

-- The Euler relation counts every point on the hull's boundary: its corners,
-- and any point lying on an edge between two of them.
local function boundary_count(pts, hp)
  local count = #hp
  for _, p in ipairs(pts) do
    for i = 1, #hp do
      local a, b = hp[i], hp[i % #hp + 1]
      local inside_x = math.min(a[1], b[1]) <= p[1] and p[1] <= math.max(a[1], b[1])
      local inside_y = math.min(a[2], b[2]) <= p[2] and p[2] <= math.max(a[2], b[2])
      local at_end = (p[1] == a[1] and p[2] == a[2]) or (p[1] == b[1] and p[2] == b[2])
      if inside_x and inside_y and not at_end and orient(a, b, p) == 0 then
        count = count + 1
        break
      end
    end
  end
  return count
end

-- Three oracles, and they catch different things:
-- (1) Euler relation  -- wrong triangle/edge COUNT
-- (2) coverage        -- HOLES: triangles missing, the rest still valid
-- (3) empty circumcircle -- triangles present but not Delaunay
-- (2) earns its place: the first version of this file produced a
-- valid-but-incomplete triangulation on 11 of 15 configurations, and (3)
-- passed on every triangle it did produce.
function M.check(pts, tris)
  -- A repeated point is one vertex: the triangulation inserts it once.
  local seen, distinct = {}, {}
  for _, p in ipairs(pts) do
    local key = ("%.17g:%.17g"):format(p[1], p[2])
    if not seen[key] then seen[key] = true; distinct[#distinct + 1] = p end
  end
  local hp = hull_points(distinct)
  local n, h = #distinct, (#hp >= 3) and boundary_count(distinct, hp) or #distinct
  -- Points that span no plane have no triangulation.
  local expect_t = (#hp >= 3) and 2 * n - h - 2 or 0
  local edges = M.edges(tris)
  local expect_e = (#hp >= 3) and 3 * n - h - 3 or 0
  if #tris ~= expect_t then
    return false, ("triangle count %d, Euler expects %d (n=%d, h=%d)")
      :format(#tris, expect_t, n, h)
  end
  if #edges ~= expect_e then
    return false, ("edge count %d, Euler expects %d (n=%d, h=%d)")
      :format(#edges, expect_e, n, h)
  end
  -- Coverage: the triangles must tile the convex hull exactly.
  local tri_area = 0
  for _, t in ipairs(tris) do
    local a, b, c = pts[t[1]], pts[t[2]], pts[t[3]]
    tri_area = tri_area
      + math.abs((b[1] - a[1]) * (c[2] - a[2]) - (c[1] - a[1]) * (b[2] - a[2])) / 2
  end
  -- Fanned from the first corner, so the products stay at the data's span
  -- rather than its distance from the origin.
  local hull_area = 0
  for i = 2, #hp - 1 do
    local o, a, b = hp[1], hp[i], hp[i + 1]
    hull_area = hull_area + ((a[1] - o[1]) * (b[2] - o[2]) - (b[1] - o[1]) * (a[2] - o[2]))
  end
  hull_area = math.abs(hull_area) / 2
  if math.abs(tri_area - hull_area) > 1e-9 * hull_area then
    return false, ("coverage: triangles total %.9f, hull is %.9f (deficit %.9f)")
      :format(tri_area, hull_area, hull_area - tri_area)
  end
  for ti, t in ipairs(tris) do
    local a, b, c = pts[t[1]], pts[t[2]], pts[t[3]]
    if orient(a, b, c) == 0 then return false, ("triangle %d is degenerate"):format(ti) end
    for i, p in ipairs(pts) do
      -- exact: a point on the circle is co-circular, not a violation
      if i ~= t[1] and i ~= t[2] and i ~= t[3] and in_circumcircle(a, b, c, p) then
        return false, ("point %d lies inside triangle %d's circumcircle")
          :format(i, ti)
      end
    end
  end
  return true, ("ok: n=%d h=%d triangles=%d edges=%d"):format(n, h, #tris, #edges)
end

-- ------------------------------------------------------------------ TeX ----
-- Emits one \draw per unique edge. Coordinates are printed at fixed
-- precision so the output is byte-stable.
function M.emit_tikz(opts)
  local pts = M.points(opts)
  local tris = M.triangulate(pts)
  local es = M.edges(tris)
  for _, e in ipairs(es) do
    local a, b = pts[e[1]], pts[e[2]]
    tex.sprint(("\\draw (%.4f,%.4f) -- (%.4f,%.4f);"):format(a[1], a[2], b[1], b[2]))
  end
end

-- Self-test: `texlua myespresso-delaunay.lua`.
-- The guard has to distinguish "run as a script" from "loaded by a document".
-- Two wrong guards, both of which fire when a document loads this file:
--   `if not tex then`  -- texlua defines a tex table as well
--   `local m = ...`    -- dofile() passes no varargs either, so m is nil
-- arg[0] is the script path only in the script case.
local run_as_script = arg and arg[0] and arg[0]:match("myespresso%-delaunay%.lua$")
if run_as_script then
  local fail = 0
  for _, seed in ipairs({ 1, 42, 20260411, 7, 99991, 3, 1234, 555, 8888, 31337 }) do
    for _, n in ipairs({ 8, 12, 44, 120, 300 }) do
      local pts = M.points({ seed = seed, n = n })
      local tris = M.triangulate(pts)
      local ok, msg = M.check(pts, tris)
      print(("seed=%-9d n=%-4d %s %s"):format(seed, n, ok and "PASS" or "FAIL", msg))
      if not ok then fail = fail + 1 end
    end
  end
  -- without the rectangle's corners the hull is irregular; a floating-point
  -- in-circle test got about a third of these wrong
  local rnd, nc_fail = new_rng(2026), 0
  for _ = 1, 200 do
    local pts = {}
    for _ = 1, 40 do pts[#pts + 1] = { rnd() * 16, rnd() * 4.5 } end
    if not M.check(pts, M.triangulate(pts)) then nc_fail = nc_fail + 1 end
  end
  print(("no-corner sets: %d of 200 failed"):format(nc_fail))
  if nc_fail > 0 then fail = fail + 1 end
  -- determinism: same seed twice must give byte-identical edge lists
  local function digest(seed)
    local pts = M.points({ seed = seed, n = 44 })
    local es = M.edges(M.triangulate(pts))
    local s = {}
    for _, e in ipairs(es) do s[#s + 1] = e[1] .. "-" .. e[2] end
    return table.concat(s, ",")
  end
  local same = digest(42) == digest(42)
  local differ = digest(42) ~= digest(43)
  print(("determinism: same-seed-identical=%s different-seed-differs=%s")
    :format(tostring(same), tostring(differ)))
  if not same or not differ then fail = fail + 1 end
  print(fail == 0 and "ALL PASS" or (fail .. " FAILURE(S)"))
end

return M
