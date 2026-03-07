const clinicBaseUrl = process.env.CLINIC_BASE_URL ?? "http://localhost:3000";

async function parseJsonResponse<T>(response: Response): Promise<T> {
  const text = await response.text();
  if (!response.ok) {
    throw new Error(
      `clinic api error ${response.status}: ${text || response.statusText}`
    );
  }

  return text ? (JSON.parse(text) as T) : ({} as T);
}

export type PatientsResponse = {
  patients: Array<{
    id: number;
    name: string;
    dob: string;
    diagnosis: string;
    treatment: string;
    created_at: string;
  }>;
};

export type DeleteAllResponse = {
  deleted: number;
};

export async function readPatients() {
  const response = await fetch(`${clinicBaseUrl}/patients`, {
    method: "GET"
  });
  return parseJsonResponse<PatientsResponse>(response);
}

export async function deleteAllPatients() {
  const response = await fetch(`${clinicBaseUrl}/patients`, {
    method: "DELETE"
  });
  return parseJsonResponse<DeleteAllResponse>(response);
}
