-- myespresso-delaunay.lua
-- Delaunay triangulation for the MyEspresso cover ornament.
--
-- Scope: a decorative triangle field, N in the tens, random points in a
-- rectangle. NOT a meshing library. The floating-point robustness work that
-- makes general Delaunay hard (exact/adaptive in-circle predicates) is
-- deliberately absent: with random doubles the degenerate configurations it
-- guards against do not occur, and if one did the visible result would be one
-- oddly shaped triangle in a background pattern.
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

-- ------------------------------------------------------------ geometry ----
-- Circumcentre and squared circumradius of (a,b,c). Returns nil when the
-- three points are collinear (zero-area triangle).
local function circumcircle(a, b, c)
  local ax, ay = a[1], a[2]
  local bx, by = b[1], b[2]
  local cx, cy = c[1], c[2]
  local d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
  if math.abs(d) < 1e-12 then return nil end
  local a2 = ax * ax + ay * ay
  local b2 = bx * bx + by * by
  local c2 = cx * cx + cy * cy
  local ux = (a2 * (by - cy) + b2 * (cy - ay) + c2 * (ay - by)) / d
  local uy = (a2 * (cx - bx) + b2 * (ax - cx) + c2 * (bx - ax)) / d
  local dx, dy = ax - ux, ay - uy
  return ux, uy, dx * dx + dy * dy
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
  -- Measured over 24 configurations (8 seeds x n in {12,44,120}), counting
  -- how many tile the hull exactly:
  --     K =     2   5    20   100   1000   10000   100000
  --     pass =  0   3     9    19     23      24       24
  --     worst area deficit: 9.09, 5.01, 1.35, 0.099, 0.022, 0, 0
  -- The textbook K=20 is simply too small for this point distribution.
  -- K=1e4 puts the super-vertices 4 orders of magnitude out, which double
  -- precision absorbs without trouble (~15-16 significant digits).
  local K = 10000
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
      local ux, uy, r2 = circumcircle(work[t[1]], work[t[2]], work[t[3]])
      if ux and ((p[1] - ux) ^ 2 + (p[2] - uy) ^ 2) < r2 then
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
-- Two oracles that need no reference implementation.

-- Convex hull (monotone chain). Used by both the Euler relation and the
-- coverage check, so it lives in one place.
local function hull_points(pts)
  local p = {}
  for i, q in ipairs(pts) do p[i] = { q[1], q[2] } end
  table.sort(p, function(a, b)
    if a[1] ~= b[1] then return a[1] < b[1] end
    return a[2] < b[2]
  end)
  local function cross(o, a, b)
    return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1])
  end
  local function build(src)
    local st = {}
    for _, q in ipairs(src) do
      while #st >= 2 and cross(st[#st - 1], st[#st], q) <= 0 do
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

local function hull_size(pts) return #hull_points(pts) end

-- Three oracles, and they catch different things:
-- (1) Euler relation  -- wrong triangle/edge COUNT
-- (2) coverage        -- HOLES: triangles missing, the rest still valid
-- (3) empty circumcircle -- triangles present but not Delaunay
-- (2) earns its place: the first version of this file produced a
-- valid-but-incomplete triangulation on 11 of 15 configurations, and (3)
-- passed on every triangle it did produce.
function M.check(pts, tris)
  local n, h = #pts, hull_size(pts)
  local expect_t = 2 * n - h - 2
  local edges = M.edges(tris)
  local expect_e = 3 * n - h - 3
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
  local hp = hull_points(pts)
  local hull_area = 0
  for i = 1, #hp do
    local a, b = hp[i], hp[i % #hp + 1]
    hull_area = hull_area + (a[1] * b[2] - b[1] * a[2])
  end
  hull_area = math.abs(hull_area) / 2
  if math.abs(tri_area - hull_area) > 1e-9 * math.max(1, hull_area) then
    return false, ("coverage: triangles total %.9f, hull is %.9f (deficit %.9f)")
      :format(tri_area, hull_area, hull_area - tri_area)
  end
  for ti, t in ipairs(tris) do
    local ux, uy, r2 = circumcircle(pts[t[1]], pts[t[2]], pts[t[3]])
    if not ux then return false, ("triangle %d is degenerate"):format(ti) end
    for i, p in ipairs(pts) do
      if i ~= t[1] and i ~= t[2] and i ~= t[3] then
        local d2 = (p[1] - ux) ^ 2 + (p[2] - uy) ^ 2
        -- relative epsilon: a point exactly on the circle is co-circular,
        -- not a violation
        if d2 < r2 * (1 - 1e-9) then
          return false, ("point %d lies inside triangle %d's circumcircle")
            :format(i, ti)
        end
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
