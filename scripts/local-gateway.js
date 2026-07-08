#!/usr/bin/env node

const http = require("http");

const PORT = 8080;

const API_ROUTES = [
  { prefix: "/api/auth", port: 8081 },
  { prefix: "/api/hospitals", port: 8082 },
  { prefix: "/api/patients", port: 8083 },
  { prefix: "/api/doctors", port: 8084 },
  { prefix: "/api/appointments", port: 8085 },
  { prefix: "/api/notifications", port: 8086 },
];

function setCorsHeaders(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader(
    "Access-Control-Allow-Methods",
    "GET, POST, PUT, PATCH, DELETE, OPTIONS",
  );
  res.setHeader(
    "Access-Control-Allow-Headers",
    "Authorization, Content-Type, X-Refresh-Token",
  );
}

function resolveTargetPort(urlPath) {
  const route = API_ROUTES.find(
    (item) =>
      urlPath === item.prefix ||
      urlPath.startsWith(`${item.prefix}/`) ||
      urlPath.startsWith(`${item.prefix}?`),
  );
  return route ? route.port : 5173;
}

function normalizeApiPath(urlPath) {
  const [pathname, query = ""] = urlPath.split("?", 2);
  const normalizedPathname = pathname
    .replace(/^\/api\/hospitals\/$/, "/api/hospitals")
    .replace(/^\/api\/patients\/$/, "/api/patients")
    .replace(/^\/api\/doctors\/$/, "/api/doctors")
    .replace(/^\/api\/appointments\/$/, "/api/appointments")
    .replace(/^\/api\/notifications\/$/, "/api/notifications");
  return query ? `${normalizedPathname}?${query}` : normalizedPathname;
}

function proxyRequest(req, res) {
  const rawUrl = req.url || "/";
  const url = normalizeApiPath(rawUrl);
  const targetPort = resolveTargetPort(url);

  const proxyReq = http.request(
    {
      hostname: "127.0.0.1",
      port: targetPort,
      method: req.method,
      path: url,
      headers: {
        ...req.headers,
        host: req.headers.host || `127.0.0.1:${targetPort}`,
      },
    },
    (proxyRes) => {
      setCorsHeaders(res);
      res.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
      proxyRes.pipe(res);
    },
  );

  proxyReq.on("error", () => {
    setCorsHeaders(res);
    res.writeHead(502, { "Content-Type": "application/json" });
    res.end(
      JSON.stringify({
        status: 502,
        error: "Bad Gateway",
        message: `Upstream service unavailable on port ${targetPort}`,
      }),
    );
  });

  req.pipe(proxyReq);
}

const server = http.createServer((req, res) => {
  const url = req.url || "/";

  if (url === "/health") {
    setCorsHeaders(res);
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "UP", gateway: "local-node" }));
    return;
  }

  if (req.method === "OPTIONS") {
    setCorsHeaders(res);
    res.writeHead(204);
    res.end();
    return;
  }

  proxyRequest(req, res);
});

server.listen(PORT, "0.0.0.0", () => {
  // eslint-disable-next-line no-console
  console.log(`Local gateway listening on http://localhost:${PORT}`);
});
