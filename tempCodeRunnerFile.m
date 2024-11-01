figure;
jth = 1;
for ith = 1: 1: length(numSym)
    plot(noisePwrSim_dBm, overHeadSim_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', markerSpace(1, jth), 'LineStyle', 'none', 'DisplayName', ['Short ACK sim with', num2str(numSym(1, ith)./2),' bytes']);
    hold on;
    plot(noisePwrSim_dBm, overHeadAna_ShortSignal(ith, :), 'Color', colorSpace(1, 1),...
        'Marker', 'none', 'LineStyle', lineSpace(1, jth), 'DisplayName', ['Short ACK ana with', num2str(numSym(1, ith)./2),' bytes']);
    hold on;

    plot(noisePwrSim_dBm, overHeadSim_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', markerSpace(1, jth), 'LineStyle', 'none', 'DisplayName', ['Long ACK sim with', num2str(numSym(1, ith)./2),' bytes']);
    hold on;
    plot(noisePwrSim_dBm, overHeadSim_LongSignal(ith, :), 'Color', colorSpace(1, 2),...
        'Marker', 'none', 'LineStyle', lineSpace(1, jth), 'DisplayName', ['Long ACK ana with', num2str(numSym(1, ith)./2),' bytes']);
    hold on;

    jth = jth + 1;
end
% axis([min(noisePwrSim_dBm), max(noisePwrSim_dBm), 0, 1]);
xlabel('Noise power (dBm)', 'Interpreter', 'latex');
ylabel('Packet delivery overhead ($$\mu s$$) $$T$$', 'Interpreter','Latex')
legend('location', 'best', 'Interpreter','Latex', 'FontSize', 7.5, 'NumColumns',2);