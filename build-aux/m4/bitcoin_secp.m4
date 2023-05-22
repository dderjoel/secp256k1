dnl escape "$0x" below using the m4 quadrigaph @S|@, and escape it again with a \ for the shell.
AC_DEFUN([SECP_X86_64_ASM_CHECK],[
AC_MSG_CHECKING(for x86_64 assembly availability)
AC_LINK_IFELSE([AC_LANG_PROGRAM([[
  #include <stdint.h>]],[[
  uint64_t a = 11, tmp;
  __asm__ __volatile__("movq \@S|@0x100000000,%1; mulq %%rsi" : "+a"(a) : "S"(tmp) : "cc", "%rdx");
  ]])], [has_x86_64_asm=yes], [has_x86_64_asm=no])
AC_MSG_RESULT([$has_x86_64_asm])
])

AC_DEFUN([SECP_ARM32_ASM_CHECK], [
  AC_MSG_CHECKING(for ARM32 assembly availability)
  SECP_ARM32_ASM_CHECK_CFLAGS_saved_CFLAGS="$CFLAGS"
  CFLAGS="-x assembler"
  AC_LINK_IFELSE([AC_LANG_SOURCE([[
    .syntax unified
    .eabi_attribute 24, 1
    .eabi_attribute 25, 1
    .text
    .global main
    main:
      ldr r0, =0x002A
      mov r7, #1
      swi 0   
    ]])], [has_arm32_asm=yes], [has_arm32_asm=no])
  AC_MSG_RESULT([$has_arm32_asm])
  CFLAGS="$SECP_ARM32_ASM_CHECK_CFLAGS_saved_CFLAGS"
])

AC_DEFUN([SECP_VALGRIND_CHECK],[
AC_MSG_CHECKING([for valgrind support])
if test x"$has_valgrind" != x"yes"; then
  CPPFLAGS_TEMP="$CPPFLAGS"
  CPPFLAGS="$VALGRIND_CPPFLAGS $CPPFLAGS"
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
    #include <valgrind/memcheck.h>
  ]], [[
    #if defined(NVALGRIND)
    #  error "Valgrind does not support this platform."
    #endif
  ]])], [has_valgrind=yes])
  CPPFLAGS="$CPPFLAGS_TEMP"
fi
AC_MSG_RESULT($has_valgrind)
])

dnl SECP_TRY_APPEND_CFLAGS(flags, VAR)
dnl Append flags to VAR if CC accepts them.
AC_DEFUN([SECP_TRY_APPEND_CFLAGS], [
  AC_MSG_CHECKING([if ${CC} supports $1])
  SECP_TRY_APPEND_CFLAGS_saved_CFLAGS="$CFLAGS"
  CFLAGS="$1 $CFLAGS"
  AC_COMPILE_IFELSE([AC_LANG_SOURCE([[char foo;]])], [flag_works=yes], [flag_works=no])
  AC_MSG_RESULT($flag_works)
  CFLAGS="$SECP_TRY_APPEND_CFLAGS_saved_CFLAGS"
  if test x"$flag_works" = x"yes"; then
    $2="$$2 $1"
  fi
  unset flag_works
  AC_SUBST($2)
])

dnl SECP_SET_DEFAULT(VAR, default, default-dev-mode)
dnl Set VAR to default or default-dev-mode, depending on whether dev mode is enabled
AC_DEFUN([SECP_SET_DEFAULT], [
  if test "${enable_dev_mode+set}" != set; then
    AC_MSG_ERROR([[Set enable_dev_mode before calling SECP_SET_DEFAULT]])
  fi
  if test x"$enable_dev_mode" = x"yes"; then
    $1="$3"
  else
    $1="$2"
  fi
])

dnl  based on
dnl  http://git.savannah.gnu.org/gitweb/?p=autoconf-archive.git;a=blob_plain;f=m4/ax_gcc_x86_cpuid.m4

AC_DEFUN([SECP_CHECK_BMI2],
[SECP_X86_CPUID_CHECK(7, 0, ebx, 8)
    if test x"$secp_x86_cpuid_7_0_ebx_8" == x"1"; then 
        HAVE_CPU_FEATURE_BMI2=yes
    else
        HAVE_CPU_FEATURE_BMI2=no
    fi
])

AC_DEFUN([SECP_CHECK_ADX],
[SECP_X86_CPUID_CHECK(7, 0, ebx, 19)
    if test x"$secp_x86_cpuid_7_0_ebx_19" == x"1"; then 
        HAVE_CPU_FEATURE_ADX=yes
    else
        HAVE_CPU_FEATURE_ADX=no
    fi
])

dnl  $1 EAX value
dnl  $2 ECX value
dnl  $3 (eax,ebx,ecx,edx) register to check
dnl  $4 (integer 0..63) Bit to check reg ($3)
dnl
dnl  then sets variable secp_x86_cpuid_$1_$2_$3_$4 to '1' or '0'
AC_DEFUN([SECP_X86_CPUID_CHECK],
[AC_REQUIRE([AC_PROG_CC])
AC_LANG_PUSH([C])
AC_CACHE_CHECK(for x86 cpuid $1_$2_$3_$4 output, secp_x86_cpuid_$1_$2_$3_$4,
 [AC_RUN_IFELSE([AC_LANG_PROGRAM([#include <stdio.h>], [
     int op = $1, level = $2, eax, ebx, ecx, edx;
     FILE *f;
      __asm__ __volatile__ ("xchg %%ebx, %1\n"
        "cpuid\n"
        "xchg %%ebx, %1\n"
        : "=a" (eax), "=r" (ebx), "=c" (ecx), "=d" (edx)
        : "a" (op), "2" (level));

     f = fopen("secp_conftest_cpuid", "w"); if (!f) return 1;
     fprintf(f, "%d\n", ($3 >> $4) & 0x1 );
     fclose(f);
     return 0;
])],
     [secp_x86_cpuid_$1_$2_$3_$4=`cat secp_conftest_cpuid`; rm -f secp_conftest_cpuid],
     [secp_x86_cpuid_$1_$2_$3_$4=unknown; rm -f secp_conftest_cpuid],
     [secp_x86_cpuid_$1_$2_$3_$4=unknown])])
AC_LANG_POP([C])
])
