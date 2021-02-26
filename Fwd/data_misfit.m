function data_misfit(testPath, predPath, savePath)

    test_dataGrouplist = dir([testPath '/' '*.mat']);
    test_data = [];
    for i = 1:length(test_dataGrouplist)
        temp = load([testPath '/' test_dataGrouplist(i).name]);
        test_data = [test_data; temp.data];
    end

    pred_dataGrouplist = dir([predPath '/' '*.mat']);
    pred_data = [];
    for i = 1:length(pred_dataGrouplist)
        temp = load([predPath '/' pred_dataGrouplist(i).name]);
        pred_data = [pred_data; temp.data];
    end

    % pre-settings
    eps = 0.05;
    misfit5 = zeros(size(test_data, 1), 1);
    rmse = zeros(size(test_data, 1), 1);
    relative_diff = zeros(size(test_data, 1), 1);
    ddEx = zeros(size(test_data, 1), 51, 51);
    ddEy = zeros(size(test_data, 1), 51, 51);

    for i = 1: size(test_data, 1)
        % Test dataset
        dE0 = test_data(i, :);
        dE0_x = test_data(i, 1:size(test_data, 2)/2);
        dE0_y = test_data(i, size(test_data, 2)/2 + 1:end);
        E0_amp = repmat(sqrt(dE0_x.^2 + dE0_y.^2), 1, 2);

        % Prediction dataset
        dE1 = pred_data(i, :);
        dE1_x = pred_data(i, 1:size(pred_data, 2)/2);
        dE1_y = pred_data(i, size(pred_data, 2)/2 + 1:end);
        
        % Difference of time differential E-field between test and pred dataset
        ddE = dE1 - dE0;
        ddEx(i, :, :) = reshape(dE1_x - dE0_x, 51, 51);
        ddEy(i, :, :) = reshape(dE1_y - dE0_y, 51, 51);
        
        % Calculate data misfit or difference
        misfit5(i) = sum((ddE ./ (E0_amp .* eps)).^2);
        rmse(i) = sqrt(sum((ddE).^2) / length(ddE));
        relative_diff(i) = sum(abs(ddE ./ dE0)) / length(ddE);
    end

    % [misfit_sorted, id_misfit] = sort(misfit5);
    [relative_diff_sorted, id_rel_diff] = sort(relative_diff);

    disp(mean(relative_diff))

    save([savePath '/' 'relative_diff_on_test_dataset.mat'], 'relative_diff_sorted', 'id_rel_diff');
end
