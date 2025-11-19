# Takes an RGB input like '#c1a484' or 'c1a484' and returns { r: int, g: int, b: int }
export def from-rgb [
  input?: string # Hex code to get the color values from
]: [string -> record<r: int, g: int, b: int>, any -> record<r: int, g: int, b: int>] {
  default -e $input
  | str replace -a '#' ''
  | split chars
  | chunks 2
  | each { str join | decode hex | into int }
  | { r: $in.0, g: $in.1, b: $in.2 }
}

# Takes an RGB color and converts it into a hex color code
export def to-rgb [
  red?: int, # 0-255, defaults to the pipeline input's $.r if pipeline has it
  green?: int, # 0-255, defaults to the pipeline input's $.g if pipeline has it
  blue?: int # 0-255, defaults to the pipeline input's $.b if pipeline has it
]: [ record<r: int, g: int, b: int> -> string, any -> string ] {
  default -e {}
  | default $red r
  | default $green g
  | default $blue b
  | [ $in.r, $in.g, $in.b ]
  | each { into binary -c }
  | bytes collect
  | encode hex
  | $'#($in)'
}
