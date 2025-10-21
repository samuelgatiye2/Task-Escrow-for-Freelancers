import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const client = accounts.get("wallet_1")!;
const freelancer = accounts.get("wallet_2")!;

describe("Task Escrow for Freelancers with Analytics", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("can create a new task with escrow", () => {
    const { result } = simnet.callPublicFn(
      "task-escrow-freelancers",
      "create-task",
      [
        simnet.types.principal(freelancer),
        simnet.types.ascii("Website Development"),
        simnet.types.ascii("Build a responsive React website"),
        simnet.types.uint(1000000), // 1 STX
        simnet.types.uint(3), // 3 milestones
        simnet.types.uint(1000), // deadline
      ],
      client
    );
    
    expect(result).toBeOk(simnet.types.uint(1));
  });

  it("returns correct platform overview stats", () => {
    const { result } = simnet.callReadOnlyFn(
      "task-escrow-freelancers",
      "get-platform-overview",
      [],
      deployer
    );
    
    const stats = result.expectTuple();
    expect(stats["platform-fee-percent"]).toBeUint(250); // 2.5%
  });

  it("allows rating users", () => {
    const { result } = simnet.callPublicFn(
      "task-escrow-freelancers",
      "rate-user",
      [simnet.types.principal(freelancer), simnet.types.uint(5)],
      client
    );
    
    expect(result).toBeOk(simnet.types.bool(true));
  });

  it("enforces proper access control", () => {
    // Only contract owner can set platform fee
    const feeResult = simnet.callPublicFn(
      "task-escrow-freelancers",
      "set-platform-fee",
      [simnet.types.uint(300)],
      client // Not the owner
    );
    
    expect(feeResult.result).toBeErr(simnet.types.uint(100)); // ERR_NOT_AUTHORIZED
  });
});
