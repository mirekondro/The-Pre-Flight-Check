// Rigged to fail TYPECHECK under `strict: true`.
//
// `lookupUser` may return undefined (the record might not exist), but the
// signature of `greet` requires a string. Passing the lookup result directly
// triggers TS2345: "Argument of type 'string | undefined' is not assignable
// to parameter of type 'string'."

const users: Record<string, string> = {
  alice: "Alice",
  bob: "Bob",
};

function lookupUser(id: string): string | undefined {
  return users[id];
}

function greet(name: string): string {
  return `Hello, ${name}!`;
}

const message = greet(lookupUser("carol"));
console.log(message);
