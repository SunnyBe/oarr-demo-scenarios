const clinicBaseUrl = process.env.CLINIC_BASE_URL ?? "http://localhost:3100";

async function parseJsonResponse(response) {
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`clinic api error ${response.status}: ${text || response.statusText}`);
  }
  return text ? JSON.parse(text) : {};
}

export async function httpGet(path) {
  const response = await fetch(`${clinicBaseUrl}${path}`, { method: "GET" });
  return parseJsonResponse(response);
}

export async function httpDelete(path) {
  const response = await fetch(`${clinicBaseUrl}${path}`, { method: "DELETE" });
  return parseJsonResponse(response);
}
