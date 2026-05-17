@echo off
REM Vivado 경로 세팅 (버전에 맞게 수정)
call C:\Xilinx\Vivado\2024.2\settings64.bat

echo Vivado Tcl Batch 모드로 시뮬레이션을 시작합니다...
REM -mode batch: GUI를 띄우지 않음 / -source: 실행할 Tcl 파일 지정
call vivado -mode batch -source run_sim.tcl -notrace

echo.
echo =========================================
echo [정리] 불필요한 Vivado 임시 파일 삭제
echo =========================================
REM 시뮬레이션 종료 후 루트 폴더에 남은 찌꺼기들을 강제 삭제합니다.
if exist .Xil rmdir /S /Q .Xil
del /Q vivado*.jou vivado*.log >nul 2>&1

echo [정리] 완료
@REM pause