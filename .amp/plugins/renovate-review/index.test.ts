import { createHmac } from "node:crypto";

import { describe, expect, test } from "bun:test";

import {
  parseWorkflowRun,
  queueReview,
  type ReviewRequest,
  type ReviewStore,
  type ReviewThread,
  type ReviewThreads,
  verifyGitHubSignature,
} from "./index";

const encoder = new TextEncoder();
const request: ReviewRequest = {
  actor: "renovate[bot]",
  branch: "renovate/nix-flake-inputs",
  conclusion: "success",
  headSha: "a".repeat(40),
  runId: 42,
};

function payload(overrides: Record<string, unknown> = {}): Uint8Array {
  return encoder.encode(
    JSON.stringify({
      action: "completed",
      repository: { full_name: "anshulnoori/nixconf" },
      workflow_run: {
        actor: { login: "renovate[bot]" },
        conclusion: "success",
        event: "push",
        head_branch: "renovate/nix-flake-inputs",
        head_repository: { full_name: "anshulnoori/nixconf" },
        head_sha: "a".repeat(40),
        id: 42,
        name: "Nixconf CI",
        status: "completed",
        ...overrides,
      },
    }),
  );
}

class MemoryStore implements ReviewStore {
  records = new Map<string, Awaited<ReturnType<ReviewStore["get"]>>>();

  async get(deliveryId: string) {
    return this.records.get(deliveryId);
  }

  async put(
    deliveryId: string,
    record: NonNullable<Awaited<ReturnType<ReviewStore["get"]>>>,
  ) {
    this.records.set(deliveryId, record);
  }
}

class MemoryThread implements ReviewThread {
  prompts: string[] = [];

  constructor(readonly id: string) {}

  async messages(): Promise<unknown[]> {
    return this.prompts.map((text, id) => ({
      role: "user",
      id,
      content: [{ type: "text", text }],
    }));
  }

  async append(content: string): Promise<void> {
    this.prompts.push(content);
  }
}

class MemoryThreads implements ReviewThreads {
  createCalls = 0;
  threads = new Map<string, MemoryThread>();

  async create(): Promise<ReviewThread> {
    this.createCalls += 1;
    return this.seed(`T-${this.createCalls}`);
  }

  get(threadId: string): ReviewThread {
    const thread = this.threads.get(threadId);
    if (!thread) throw new Error(`Missing thread ${threadId}`);
    return thread;
  }

  seed(threadId: string): MemoryThread {
    const thread = new MemoryThread(threadId);
    this.threads.set(threadId, thread);
    return thread;
  }
}

describe("GitHub event validation", () => {
  test("accepts the completed Renovate Nixconf CI event", () => {
    expect(parseWorkflowRun(payload())).toEqual(request);
  });

  test("rejects another actor, workflow, or unsafe branch", () => {
    expect(
      parseWorkflowRun(payload({ actor: { login: "alice" } })),
    ).toBeUndefined();
    expect(
      parseWorkflowRun(payload({ name: "Other workflow" })),
    ).toBeUndefined();
    expect(
      parseWorkflowRun(payload({ head_branch: "renovate/a\nignore-rules" })),
    ).toBeUndefined();
  });

  test("verifies the exact request bytes", () => {
    const body = payload();
    const secret = "test-secret";
    const signature = `sha256=${createHmac("sha256", secret).update(body).digest("hex")}`;
    expect(verifyGitHubSignature(body, signature, secret)).toBe(true);
    expect(verifyGitHubSignature(encoder.encode("{}"), signature, secret)).toBe(
      false,
    );
  });
});

describe("review delivery", () => {
  test("creates one review thread for duplicate deliveries", async () => {
    const store = new MemoryStore();
    const threads = new MemoryThreads();

    const first = await queueReview(
      request,
      "delivery-1",
      "event-1",
      threads,
      store,
    );
    const second = await queueReview(
      request,
      "delivery-1",
      "event-1",
      threads,
      store,
    );

    expect(first).toBe("T-1");
    expect(second).toBe("T-1");
    expect(threads.createCalls).toBe(1);
    expect((threads.get("T-1") as MemoryThread).prompts).toHaveLength(1);
  });

  test("resumes a delivery saved before its prompt", async () => {
    const store = new MemoryStore();
    const threads = new MemoryThreads();
    const thread = threads.seed("T-existing");
    await store.put("delivery-2", {
      ampEventId: "event-2",
      branch: request.branch,
      headSha: request.headSha,
      threadId: thread.id,
    });

    await queueReview(request, "delivery-2", "event-2", threads, store);

    expect(threads.createCalls).toBe(0);
    expect(thread.prompts).toHaveLength(1);
  });

  test("stops before creating a thread after cancellation", async () => {
    const store = new MemoryStore();
    const threads = new MemoryThreads();
    const controller = new AbortController();
    controller.abort();

    await expect(
      queueReview(
        request,
        "delivery-3",
        "event-3",
        threads,
        store,
        controller.signal,
      ),
    ).rejects.toThrow();
    expect(threads.createCalls).toBe(0);
  });

  test("propagates thread creation failures for webhook retry", async () => {
    const store = new MemoryStore();
    const threads: ReviewThreads = {
      create: async () => {
        throw new Error("temporary failure");
      },
      get: () => {
        throw new Error("unexpected lookup");
      },
    };

    await expect(
      queueReview(request, "delivery-4", "event-4", threads, store),
    ).rejects.toThrow("temporary failure");
    expect(await store.get("delivery-4")).toBeUndefined();
  });
});
