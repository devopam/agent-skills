You are applying the ci-cd-plumber skill. The repo's
`.github/workflows/pr-preview.yml` triggers on `pull_request_target`,
checks out the PR head ref (`ref: ${{ github.event.pull_request.head.sha }}`),
then runs `npm install` and `npm run build` from that untrusted checkout,
using the default `GITHUB_TOKEN` with `contents: write`. There is no
`docs/ci-cd-baseline.md`. User asks: "Audit our CI/CD."
