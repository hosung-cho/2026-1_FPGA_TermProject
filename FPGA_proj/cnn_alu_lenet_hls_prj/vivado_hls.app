<AutoPilot:project xmlns:AutoPilot="com.autoesl.autopilot.project" projectType="C/C++" name="cnn_alu_lenet_hls_prj" top="CNN_ALU_Top">
    <Simulation argv="">
        <SimFlow name="csim" setup="false" optimizeCompile="false" clean="false" ldflags="" mflags=""/>
    </Simulation>
    <files>
        <file name="../../tb_lenet_int8_cnn_alu.cpp" sc="0" tb="1" cflags=" -I../.. -Wno-unknown-pragmas" csimflags=" -Wno-unknown-pragmas" blackbox="false"/>
        <file name="cnn_alu.cpp" sc="0" tb="false" cflags="-I." csimflags="" blackbox="false"/>
    </files>
    <solutions>
        <solution name="solution1" status=""/>
    </solutions>
</AutoPilot:project>

