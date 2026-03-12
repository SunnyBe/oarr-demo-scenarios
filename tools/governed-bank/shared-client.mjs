const bankBaseUrl = process.env.BANK_BASE_URL ?? "http://localhost:3101";

async function parseJsonResponse(response) {
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`bank api error ${response.status}: ${text || response.statusText}`);
  }
  return text ? JSON.parse(text) : {};
}

export async function httpGet(path) {
  const response = await fetch(`${bankBaseUrl}${path}`, { method: "GET" });
  return parseJsonResponse(response);
}

export async function httpPost(path, body) {
  const response = await fetch(`${bankBaseUrl}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  return parseJsonResponse(response);
}
