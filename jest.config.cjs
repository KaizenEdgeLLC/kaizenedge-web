/** @type {import('jest').Config} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/tests"],
  moduleFileExtensions: ["ts", "tsx", "js", "json"],
  // ✅ Modern, supported config: no deprecated `globals`
  transform: {
    "^.+\\.tsx?$": [
      "ts-jest",
      {
        tsconfig: {
          esModuleInterop: true,
          resolveJsonModule: true,
          module: "commonjs",
          strict: true
        }
      }
    ]
  }
};
