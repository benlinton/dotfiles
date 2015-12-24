#!/usr/bin/env bats

@test "no arguments prints help instructions" {
  run dotfiles
  [ $status -eq 1 ]
  [ $(expr "${lines[0]}" : "Usage:") -ne 0 ]
  [ "${#lines[@]}" -gt 3 ]
}

@test "-v and --version print version number" {
  run dotfiles -v
  [ $status -eq 0 ]
  [ $(expr "$output" : "v[0-9][0-9.]*") -ne 0 ]
}

@test "-h and --help print help" {
  run dotfiles -h
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "Usage:") -ne 0 ]
  [ "${#lines[@]}" -gt 3 ]
}

@test "-u and --uninstall run dotfiles-uninstall" {
  run dotfiles -u
  [ $status -eq 0 ]
}

@test "-i and --install run dotfiles-install" {
  run dotfiles -i
  [ $status -eq 0 ]
}
