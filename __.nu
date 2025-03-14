export def gen [] {
    const wd = path self .
    cd $wd
    let g = $env.generate
    let paths = ls
    | where type == dir
    | get name
    | filter { $in not-in $g.exclude }
    generate $paths $g
}

export def generate [
    paths
    ctx: record
] {
    let pf = $paths | reduce -f {} {|i,a|
        $a | insert $i [ $"($i)/**" ]
    }
    | to yaml
    let bs = $paths
    | each {|x|
        {
            name: $"Build ($x)"
            if: $"steps.changes.outputs.($x) == 'true' || github.event.name == 'workflow_dispatch'"
            uses: "docker/build-push-action@v4"
            with: {
              context: $x
              file: $"($x)/Dockerfile"
              push: "${{ github.event_name != 'pull_request' }}"
              tags: $"${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:($x)"
              labels: "${{ steps.meta.outputs.labels }}"
            }
        }
    }
    let wf = {
      name: $ctx.name
      on: {
        push: {
          branches: [main]
        }
        workflow_dispatch: {
          inputs: {}
        }
      }
      env: {
        REGISTRY: $ctx.registry
        IMAGE_NAME: $"($ctx.user)/($ctx.image)"
      }
      jobs: {
        build: {
          runs-on: ubuntu-latest
          if: "${{ !endsWith(github.event.head_commit.message, '~') }}"
          permissions: {
            contents: read
            packages: write
          }
          steps: [
            {
              name: "Checkout repository",
              uses: "actions/checkout@v3"
            }
            {
              name: "Log into registry ${{ env.REGISTRY }}"
              if: "github.event_name != 'pull_request'"
              uses: "docker/login-action@v2",
              with: {
                registry: "${{ env.REGISTRY }}",
                username: $ctx.user,
                password: "${{ secrets.GHCR_TOKEN }}"
              }
            }
            {
              name: "Extract Docker metadata"
              id: meta
              uses: "docker/metadata-action@v4"
              with: {
                images: "${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}"
              }
            }
            {
              uses: "dorny/paths-filter@v3"
              id: changes
              with: {
                filters: $pf
              }
            }
            ...$bs
          ]
        }
      }
    }
    | to yaml
    | save -f .github/workflows/build.yaml
}

export def list [] {
    let px = ls | where type == dir | get name
    for i in $px {
        print $"($env.REGISTRY)/($env.IMAGE_NAME):($i)"
    }
}

export def git-hooks [act ctx] {
    if $act == 'pre-commit' and $ctx.branch == 'main' {
        print $'(ansi grey)generate github actions workflow(ansi reset)'
        gen
        git add .
    }
}

export def main [] {
    gen
}
