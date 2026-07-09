export type AccessIdentity = {
  userAccountId: string | null;
  hospitalScopeId: string | null;
};

function decodeBase64Url(value: string) {
  const normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");
  return atob(padded);
}

export function decodeAccessIdentity(token: string): AccessIdentity {
  try {
    const [, payload] = token.split(".");
    if (!payload) {
      return { userAccountId: null, hospitalScopeId: null };
    }
    const decoded = JSON.parse(decodeBase64Url(payload)) as {
      userId?: string;
      hospitalId?: string;
    };
    return {
      userAccountId: decoded.userId || null,
      hospitalScopeId: decoded.hospitalId || null,
    };
  } catch {
    return { userAccountId: null, hospitalScopeId: null };
  }
}
