export def gen [] {
    const wd = path self .
    const cfg = path self ,.yaml
    cd $wd
    let g = (open $cfg).generate
    let paths = ls
    | where type == dir
    | get name
    generate $paths $g
}

export def generate [
    paths
    ctx: record
] {
    let oldpwd = $env.PWD
    for x in $paths {
        cd ([$oldpwd $x] | path join)
        let bs = ls *Dockerfile | get name
        | each {|i|
            let file = $"($x)/($i)"
            if $file in $ctx.exclude { return }
            let tag = $i | path parse
            let tag = if ($tag.extension | is-empty) {
                $x
            } else {
                $"($x)-($tag.stem)"
            }
            let w = {
              context: $x
              file: $file
              push: "${{ github.event_name != 'pull_request' }}"
              tags: $"${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:($tag)"
              labels: "${{ steps.meta.outputs.labels }}"
              build-args: ([
                "REGISTRY: ${{ env.REGISTRY }}"
                "IMAGE_NAME: ${{ env.IMAGE_NAME }}"
              ] | str join "\n")
            }
            | merge deep ($ctx.repo | get -o $x | get -o $i | default {})
            {
                name: $"Build ($x)"
                if: $"steps.changes.outputs.($x) == 'true' || github.event.name == 'workflow_dispatch'"
                uses: "docker/build-push-action@v4"
                with: $w
            }
        }

        let pf = { $x: [ $"($x)/**" ] } | to yaml

        {
          name: $"build ($x)"
          on: {
            push: {
              branches: [main, $x]
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
                    password: $"${{ ($ctx.token_ref) }}"
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
        | save -f $"($oldpwd)/.github/workflows/($x).yaml"
    }
}

export def list [] {
    let paths = ls | where type == dir | get name
    for i in $paths {
        print $"($env.REGISTRY)/($env.IMAGE_NAME):($i)"
    }
}

export def git-hooks [act ctx] {
    return
    if $act == 'pre-commit' and $ctx.branch == 'main' {
        print $'(ansi grey)generate github actions workflow(ansi reset)'
        gen
        git add .
    }
}

export def main [] {
    gen
}

export def csproj [src target] {
  mkdir $target
  let target = $env.PWD | path join $target
  cd $src
  print $env.PWD
  ls **/*.csproj
  | get name
  | where { $in | str starts-with 'src' }
  | each {|x|
      let d = $target | path join ...($x | path split | slice 1..-2 )
      print $"(ansi grey)($x) => ($d)(ansi reset)"
      mkdir $d
      cp $x $d
  }
}
