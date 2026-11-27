import { describe, expect, test } from "bun:test";
import { outputOf } from "./exit";
import { parseJson } from "./parse";
import { all, attempt, attemptSync, DONE, fail, ok, settle, settleSync, type Result } from "./result";

describe("a result", () => {
  test("holds a value, or why there is none", () => {
    expect(ok(7)).toEqual({ ok: true, value: 7 });
    expect(fail("the machine is away")).toEqual({ ok: false, error: "the machine is away" });
    expect(DONE.ok).toBe(true);
  });

  test("is the value of work that ends well", async () => {
    expect(await attempt(async () => "done")).toEqual(ok("done"));
  });

  test("is a failure with the words of what work rejects with", async () => {
    expect(await attempt(() => Promise.reject(new Error("gh is not installed")))).toEqual(fail("gh is not installed"));
    expect(await attempt(() => Promise.reject("timed out"))).toEqual(fail("timed out"));
  });

  test("is a failure when work throws before it starts", async () => {
    const work = (): Promise<string> => {
      throw new Error("no such folder");
    };
    expect(await attempt(work)).toEqual(fail("no such folder"));
  });

  test("is the value of a step, or the words of what it throws", () => {
    expect(attemptSync(() => 7)).toEqual(ok(7));
    const step = (): number => {
      throw new Error("the layout nests too deep");
    };
    expect(attemptSync(step)).toEqual(fail("the layout nests too deep"));
  });
});

describe("steps that run at once", () => {
  test("give every value, in their order", async () => {
    const slow = new Promise<Result<string>>((resolve) => setTimeout(() => resolve(ok("a")), 5));
    expect(await all([slow, Promise.resolve(ok("b"))])).toEqual(ok(["a", "b"]));
    expect(await all([])).toEqual(ok([]));
  });

  test("fail with the first failure in their order, once all have ended", async () => {
    let ended = 0;
    const step = (result: Result<string>, after: number): Promise<Result<string>> =>
      new Promise((resolve) =>
        setTimeout(() => {
          ended++;
          resolve(result);
        }, after),
      );
    // The second failure ends first, and the last step ends well after both.
    const steps = [step(ok("a"), 1), step(fail("t3 is gone"), 6), step(fail("t4 is gone"), 2), step(ok("d"), 12)];
    expect(await all(steps)).toEqual(fail("t3 is gone"));
    expect(ended).toBe(4);
  });
});

describe("a step at the edge of work that nothing waits for", () => {
  test("gives its own result", async () => {
    expect(await settle(async () => ok(7))).toEqual(ok(7));
    expect(await settle(() => fail("gh refused"))).toEqual(fail("gh refused"));
    expect(settleSync(() => ok("set"))).toEqual(ok("set"));
    expect(settleSync(() => fail("the layout nests too deep"))).toEqual(fail("the layout nests too deep"));
  });

  test("fails with the words of a bug in it, where it would have left the person waiting", async () => {
    const rejects = async (): Promise<Result<number>> => {
      throw new TypeError("lines is not iterable");
    };
    const throws = (): Result<number> => {
      throw new TypeError("children is not a list");
    };
    expect(await settle(rejects)).toEqual(fail("lines is not iterable"));
    expect(await settle(throws)).toEqual(fail("children is not a list"));
    expect(settleSync(throws)).toEqual(fail("children is not a list"));
  });
});

describe("the run of a program", () => {
  const ended = (code: number, stdout: string, stderr: string) => ok({ code, stdout, stderr });

  test("gives what the program printed when it ended well", () => {
    expect(outputOf(ended(0, "main\n", "a warning"), "git")).toEqual(ok("main\n"));
  });

  test("fails with what the program wrote on stderr", () => {
    expect(outputOf(ended(1, "", "  no such branch\n"), "git")).toEqual(fail("no such branch"));
  });

  test("fails with the exit code of a program that wrote nothing", () => {
    expect(outputOf(ended(3, "half", " \n"), "start.sh")).toEqual(fail("start.sh ended with code 3"));
  });

  test("fails with why the program could not start", () => {
    expect(outputOf(fail("gh: command not found"), "gh")).toEqual(fail("gh: command not found"));
    expect(outputOf(fail(""), "gh")).toEqual(fail("gh could not start"));
  });
});

describe("the JSON a program printed", () => {
  test("is read, with its fields still to be checked", () => {
    expect(parseJson('{"number": 7}')).toEqual(ok({ number: 7 }));
    expect(parseJson("null")).toEqual(ok(null));
  });

  test("is a failure when it is no JSON", () => {
    const read = parseJson("<html>");
    expect(read.ok).toBe(false);
    expect(read.ok ? "" : read.error).not.toBe("");
  });
});
