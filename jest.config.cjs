/** @type {import('jest').Config} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/tests"],
  moduleFileExtensions: ["ts", "tsx", "js", "json"],
  globals: {
    "ts-jest": {
      tsconfig: {
        esModuleInterop: true,
        resolveJsonModule: true,
        module: "commonjs",
        strict: true
      }
    }
  }
};
