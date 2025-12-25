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
