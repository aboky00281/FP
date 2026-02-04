<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>คำนวณขนาดปั๊มดับเพลิงและถังเก็บน้ำ (NFPA Guidance) V.2.10</title>
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2.2.0"></script>

    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Sarabun:wght@300;400;500;600;700&family=Prompt:wght@400;500;600;700&display=swap" rel="stylesheet">
    
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Sarabun', 'sans-serif'],
                        heading: ['Prompt', 'sans-serif'],
                    },
                    colors: {
                        slate: {
                            850: '#1e293b', // Custom dark slate
                        },
                        brand: {
                            500: '#0ea5e9',
                            600: '#0284c7',
                        }
                    },
                    keyframes: {
                        'fade-in-down': {
                            '0%': { opacity: '0', transform: 'translateY(-10px)' },
                            '100%': { opacity: '1', transform: 'translateY(0)' },
                        }
                    },
                    animation: {
                        'fade-in-down': 'fade-in-down 0.5s ease-out',
                    }
                }
            }
        }
    </script>
    <style>
        body {
            background-color: #f8fafc; /* Slate 50 */
        }
        
        /* Modern Input Style with floating label feeling */
        .input-wrapper {
            position: relative;
        }
        
        .input-field {
            width: 100%;
            padding: 0.75rem 1rem;
            /* Increased padding-right to create more gap between number and unit */
            padding-right: 4.5rem; 
            background-color: #ffffff;
            border: 1px solid #e2e8f0;
            border-radius: 0.5rem;
            font-family: 'Sarabun', sans-serif;
            font-size: 1rem;
            color: #334155;
            transition: all 0.2s;
        }
        
        .input-field:focus {
            outline: none;
            border-color: #0ea5e9;
            box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1);
        }

        .input-unit {
            position: absolute;
            right: 1.25rem; /* Adjusted right position for better balance */
            top: 50%;
            transform: translateY(-50%);
            color: #64748b; /* Slightly darker for better readability */
            font-size: 0.875rem;
            font-weight: 500;
            pointer-events: none;
        }

        .section-card {
            background: white;
            border: 1px solid #e2e8f0;
            border-radius: 1rem;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
        }

        /* Print Adjustments */
        @media print {
            body { background: white !important; }
            .no-print { display: none !important; }
            .section-card { border: 1px solid #ccc !important; box-shadow: none !important; }
            #results, #chart_section { page-break-inside: avoid; }
            canvas { max-height: 400px !important; }
            .bg-cover { background-image: none !important; background-color: #eee !important; color: black !important; }
        }
    </style>
</head>
<body class="text-slate-600 antialiased min-h-screen">

    <!-- Top Navigation Bar -->
    <nav class="bg-white border-b border-slate-200 sticky top-0 z-40 no-print">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between h-16">
                <div class="flex items-center">
                    <div class="flex-shrink-0 flex items-center">
                         <div class="w-8 h-8 bg-brand-500 rounded-lg flex items-center justify-center text-white font-bold mr-3">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
                         </div>
                         <h1 class="font-heading text-xl font-bold text-slate-800">Fire Pump Calculator <span class="text-xs font-normal text-slate-400 ml-2 border border-slate-200 px-2 py-0.5 rounded-full">V.2.10</span></h1>
                    </div>
                </div>
                <div class="flex items-center">
                     <button onclick="window.print()" class="text-slate-400 hover:text-brand-600 transition-colors p-2 rounded-full hover:bg-slate-50" title="Print / Save PDF">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path></svg>
                     </button>
                </div>
            </div>
        </div>
    </nav>

    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
            
            <!-- Left Sidebar: Inputs -->
            <div class="lg:col-span-4 space-y-6">
                
                <!-- Section 1: Design Criteria -->
                <div class="section-card p-6">
                    <div class="flex items-center mb-5 pb-4 border-b border-slate-100">
                        <span class="w-6 h-6 rounded-full bg-slate-100 text-slate-600 flex items-center justify-center text-xs font-bold mr-3">1</span>
                        <h2 class="font-heading text-lg font-semibold text-slate-800">ข้อมูลพื้นที่ (Design Criteria)</h2>
                    </div>

                    <div class="space-y-5">
                        <div class="input-wrapper">
                            <label class="block text-sm font-medium text-slate-700 mb-1">ชื่อพื้นที่ / โซน</label>
                            <input type="text" id="area_name" class="input-field" placeholder="ระบุชื่ออาคาร" style="padding-right: 1rem;">
                        </div>

                        <div class="input-wrapper">
                            <label class="block text-sm font-medium text-slate-700 mb-1">ระดับความอันตราย</label>
                            <div class="relative">
                                <select id="hazard_class" onchange="checkWarnings()" class="input-field appearance-none cursor-pointer bg-slate-50 hover:bg-white border-slate-200">
                                    <option value="light">Light Hazard (น้อย)</option>
                                    <option value="ordinary1">Ordinary Group 1 (ปานกลาง 1)</option>
                                    <option value="ordinary2">Ordinary Group 2 (ปานกลาง 2)</option>
                                    <option value="extra1">Extra Group 1 (มาก 1)</option>
                                    <option value="extra2">Extra Group 2 (มาก 2)</option>
                                </select>
                                <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-3 text-slate-500">
                                    <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                                </div>
                            </div>
                        </div>

                        <div class="grid grid-cols-2 gap-4">
                            <div class="input-wrapper">
                                <label class="block text-sm font-medium text-slate-700 mb-1">พื้นที่</label>
                                <div class="relative">
                                    <input type="number" id="design_area" class="input-field text-right font-semibold text-brand-600" placeholder="139.4" step="0.1">
                                    <span class="input-unit">ตร.ม.</span>
                                </div>
                            </div>
                            <div class="input-wrapper">
                                <label class="block text-sm font-medium text-slate-700 mb-1">เวลา</label>
                                <div class="relative">
                                    <select id="duration" onchange="checkWarnings()" class="input-field text-right font-semibold cursor-pointer appearance-none text-brand-600">
                                        <option value="30">30</option>
                                        <option value="60">60</option>
                                        <option value="90">90</option>
                                        <option value="120">120</option>
                                    </select>
                                    <span class="input-unit">นาที</span>
                                </div>
                            </div>
                        </div>

                        <!-- Info/Warning Box -->
                        <div id="warning_box" class="hidden bg-amber-50 border border-amber-100 rounded-lg p-3 flex gap-3 text-xs text-amber-800">
                            <svg class="w-4 h-4 text-amber-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
                            <span id="warning_text"></span>
                        </div>

                        <div class="flex justify-end">
                            <button onclick="showImagePopup('https://img2.pic.in.th/pic/Screenshot-2025-07-16-004620.png')" class="text-xs text-slate-400 hover:text-brand-600 underline flex items-center">
                                <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                                ดูตารางอ้างอิง NFPA
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Action Buttons (Moved Here) -->
                <div class="grid grid-cols-3 gap-4 mt-4 no-print">
                    <button onclick="calculate()" class="col-span-2 bg-brand-600 hover:bg-brand-700 text-white font-heading font-medium py-3 px-4 rounded-xl shadow-md hover:shadow-lg transition-all flex items-center justify-center">
                        <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z"></path></svg>
                        คำนวณ
                    </button>
                    <button onclick="clearData()" class="col-span-1 bg-white border border-slate-200 text-slate-500 hover:text-red-600 hover:border-red-200 font-heading font-medium py-3 px-4 rounded-xl shadow-sm transition-all text-center">
                        ล้างค่า
                    </button>
                </div>

                <!-- Result Cards (Moved to Left Column) -->
                <div id="result_cards_container" class="hidden grid grid-cols-1 gap-4 mt-6 mb-6 animate-fade-in-down">
                    
                    <!-- Total Flow Demand -->
                    <div class="relative rounded-2xl p-4 text-white shadow-md overflow-hidden group h-28 flex flex-col justify-between">
                        <div class="absolute inset-0 z-0 bg-cover bg-center transition-transform duration-700 group-hover:scale-105" 
                                style="background-image: url('https://images.unsplash.com/photo-1541675154750-0444c7d51e8e?auto=format&fit=crop&w=800&q=80');"></div>
                        <div class="absolute inset-0 bg-blue-900/70 z-10 backdrop-blur-[1px]"></div>
                        
                        <div class="relative z-20 flex justify-between items-start">
                            <p class="text-blue-100 text-sm font-medium font-heading">Total Flow Demand</p>
                            <svg class="w-5 h-5 text-blue-200 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
                        </div>
                        <div class="relative z-20 flex items-baseline">
                            <span id="total_flow" class="text-3xl font-bold font-heading">0</span>
                            <span class="ml-1 text-blue-200 text-xs font-medium">GPM</span>
                        </div>
                        <div class="relative z-20 text-[10px] text-blue-200">Water Supply Required</div>
                    </div>

                    <!-- Tank Volume -->
                    <div class="relative rounded-2xl p-4 text-white shadow-md overflow-hidden group h-28 flex flex-col justify-between">
                        <div class="absolute inset-0 z-0 bg-cover bg-center transition-transform duration-700 group-hover:scale-105" 
                                style="background-image: url('https://images.unsplash.com/photo-1589923188900-85dae5233271?q=80&w=800&auto=format&fit=crop');"></div>
                        <div class="absolute inset-0 bg-slate-900/70 z-10 backdrop-blur-[1px]"></div>

                        <div class="relative z-20 flex justify-between items-start">
                            <p class="text-slate-200 text-sm font-medium font-heading">ปริมาตรถังเก็บน้ำ</p>
                            <svg class="w-5 h-5 text-slate-300 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path></svg>
                        </div>
                        <div class="relative z-20 flex items-baseline">
                            <span id="tank_volume" class="text-3xl font-bold font-heading">0.00</span>
                            <span class="ml-1 text-slate-200 text-xs font-medium">ลบ.ม.</span>
                        </div>
                        <div class="relative z-20 flex items-center text-[10px] text-slate-300">
                            <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                            สำรองน้ำ <span id="actual_duration_display" class="mx-1 font-bold text-white">0</span> นาที
                        </div>
                    </div>

                    <!-- Recommended Pump -->
                    <div class="relative rounded-2xl p-4 text-white shadow-md overflow-hidden group h-28 flex flex-col justify-between">
                        <div class="absolute inset-0 z-0 bg-cover bg-center transition-transform duration-700 group-hover:scale-105" 
                                style="background-image: url('https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=800&auto=format&fit=crop');"></div>
                        <div class="absolute inset-0 bg-red-900/80 z-10 backdrop-blur-[1px]"></div>

                        <div class="relative z-20 flex justify-between items-start">
                            <p class="text-red-100 text-sm font-medium font-heading">แนะนำขนาดปั๊ม</p>
                            <svg class="w-5 h-5 text-red-200 opacity-80" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                        </div>
                        <div class="relative z-20 flex items-baseline">
                            <span class="text-lg font-bold mr-1 text-red-200">≥</span>
                            <span id="summary_recommended_pump_flow_card" class="text-3xl font-bold font-heading">0</span>
                            <span class="ml-1 text-red-100 text-xs font-medium">GPM</span>
                        </div>
                        <div class="relative z-20 text-[10px] text-red-200">
                            ที่แรงดัน <span id="summary_demand_head_card" class="font-bold text-white">0</span> PSI
                        </div>
                    </div>
                </div>

                <!-- Section 2: Pump Spec -->
                <div id="pump_definition_section" class="section-card p-6 mb-0">
                    <div class="flex items-center mb-5 pb-4 border-b border-slate-100">
                        <span class="w-6 h-6 rounded-full bg-slate-100 text-slate-600 flex items-center justify-center text-xs font-bold mr-3">2</span>
                        <h2 class="font-heading text-lg font-semibold text-slate-800">ข้อมูลปั๊ม (Pump Spec)</h2>
                    </div>

                    <div class="space-y-5">
                        <div class="input-wrapper">
                            <label class="block text-sm font-medium text-slate-700 mb-1">ชนิดปั๊ม (Pump Type)</label>
                            <div class="relative">
                                <select id="pump_type" class="input-field appearance-none cursor-pointer bg-slate-50 hover:bg-white border-slate-200">
                                    <option value="horizontal">Horizontal Split Case</option>
                                    <option value="vertical">Vertical Turbine</option>
                                </select>
                                <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-3 text-slate-500">
                                    <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                                </div>
                            </div>
                        </div>

                        <div class="grid grid-cols-2 gap-4">
                            <div class="input-wrapper">
                                <label class="block text-sm font-medium text-slate-700 mb-1">Rated Flow</label>
                                <div class="relative">
                                    <input type="number" id="pump_rated_flow" class="input-field text-right font-semibold text-slate-800" placeholder="0" step="10">
                                    <span class="input-unit">GPM</span>
                                </div>
                            </div>
                            <div class="input-wrapper">
                                <label class="block text-sm font-medium text-slate-700 mb-1">Rated Head</label>
                                <div class="relative">
                                    <input type="number" id="system_demand_head" class="input-field text-right font-semibold text-slate-800" placeholder="0" step="1">
                                    <span class="input-unit">PSI</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            <!-- Right Column: Results -->
            <div class="lg:col-span-8 space-y-6">

                <!-- Results Section -->
                <div id="results" class="hidden space-y-6">
                    
                    <!-- Chart Section -->
                    <div id="chart_section" class="section-card overflow-hidden mt-0 mb-0 group relative">
                         <!-- Background for Chart -->
                         <div class="absolute inset-0 z-0 bg-cover bg-center opacity-5 transition-transform duration-700 group-hover:scale-105" 
                              style="background-image: url('https://media.istockphoto.com/id/1324706599/photo/industrial-fire-protection-system.jpg?s=612x612&w=0&k=20&c=i-q_1a0v8eL2L_9a-6z2q2L4x-2a9e5L2e-2a6y-5a6o=');"></div>
                        
                         <div class="relative z-10 bg-white/80 backdrop-blur-sm p-4 border-b border-slate-100 flex justify-between items-center">
                            <h3 class="font-heading font-bold text-slate-800">กราฟสมรรถนะปั๊ม (Performance Curve)</h3>
                            <div class="text-[10px] bg-white px-2 py-1 rounded border border-slate-200 text-slate-400">
                                Simulated Data
                            </div>
                         </div>
                        
                        <div class="relative z-10 h-[450px] w-full p-4 bg-white/50">
                            <canvas id="pumpCurveChart"></canvas>
                        </div>
                        
                        <div id="graph_summary" class="relative z-10 bg-white/90 border-t border-slate-100 p-4 text-center">
                            <div class="flex flex-wrap justify-center gap-x-6 gap-y-2 text-xs text-slate-600 font-medium">
                                <div class="flex items-center"><span class="w-2.5 h-2.5 rounded-full bg-brand-500 mr-2"></span>Pump Curve</div>
                                <div class="flex items-center"><span class="w-2.5 h-2.5 bg-red-500 transform rotate-45 mr-2"></span>System Demand</div>
                                <div class="flex items-center"><span class="w-2.5 h-2.5 rounded-full bg-green-500 mr-2"></span>Rated (100%)</div>
                                <div class="flex items-center"><span class="w-2.5 h-2.5 bg-red-800 mr-2"></span>Churn</div>
                                <div class="flex items-center"><span class="w-2.5 h-2.5 bg-purple-500 mr-2 transform rotate-45"></span>Overload (150%)</div>
                            </div>
                        </div>
                    </div>

                    <!-- Summary Table -->
                    <div id="calculation_summary_section" class="section-card overflow-hidden mt-0">
                         <div class="bg-slate-50 px-6 py-4 border-b border-slate-200">
                            <h3 class="font-heading text-lg font-bold text-slate-700 mt-0 mb-0">ตารางสรุปผลการคำนวณ</h3>
                        </div>
                        <div class="overflow-x-auto">
                            <table class="w-full text-sm">
                                <tbody class="divide-y divide-slate-100">
                                    <tr>
                                        <td class="px-6 py-4 text-slate-500 w-1/2">Sprinkler Demand</td>
                                        <td class="px-6 py-4 text-right font-medium text-slate-800"><span id="summary_sprinkler_flow">0.00</span> GPM</td>
                                    </tr>
                                    <tr>
                                        <td class="px-6 py-4 text-slate-500">Hose Stream Allowance</td>
                                        <td class="px-6 py-4 text-right font-medium text-slate-800"><span id="summary_hose_allowance">0.00</span> GPM</td>
                                    </tr>
                                    <tr class="bg-brand-50/50">
                                        <td class="px-6 py-4 font-bold text-slate-700">Total Required Flow</td>
                                        <td class="px-6 py-4 text-right font-bold text-brand-600 text-base"><span id="summary_total_flow">0.00</span> GPM</td>
                                    </tr>
                                    <tr>
                                        <td class="px-6 py-4 text-slate-500">Max Churn Pressure (Est.)</td>
                                        <td class="px-6 py-4 text-right font-medium text-slate-800"><span id="summary_max_pressure">0.00</span> PSI</td>
                                    </tr>
                                    <tr>
                                        <td class="px-6 py-4 text-slate-500">Rated Head @ 100%</td>
                                        <td class="px-6 py-4 text-right font-medium text-slate-800"><span id="summary_demand_head_table">0.00</span> PSI</td>
                                    </tr>
                                    <tr class="bg-slate-50">
                                        <td class="px-6 py-4 font-bold text-slate-700">Tank Volume Required</td>
                                        <td class="px-6 py-4 text-right font-bold text-slate-800 text-base"><span id="summary_tank_volume">0.00</span> m³</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                </div> <!-- End Results Wrapper -->
                
                <!-- Initial State Placeholder -->
                <div id="initial_state_placeholder" class="h-full min-h-[400px] bg-white border-2 border-dashed border-slate-200 rounded-2xl flex flex-col items-center justify-center text-slate-400">
                    <svg class="w-16 h-16 mb-4 text-slate-200" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                    <p class="text-lg font-medium">กรอกข้อมูลทางด้านซ้ายเพื่อเริ่มคำนวณ</p>
                    <p class="text-sm text-slate-300 mt-2">ผลลัพธ์และกราฟจะแสดงที่นี่</p>
                </div>

            </div>
        </div>
    </div>

    <!-- Hidden elements for logic compatibility -->
    <div class="hidden">
        <span id="sprinkler_flow">0.00</span>
        <span id="hose_allowance">0.00</span>
        <span id="actual_duration">0</span>
        <span id="summary_actual_duration">0</span>
        <span id="summary_estimated_pressure">0.00</span>
        <span id="summary_recommended_pump_flow">0.00</span>
        <div id="display_area_name"></div>
    </div>

    <!-- Image Popup Modal -->
    <div id="imagePopupModal" class="fixed inset-0 bg-slate-900/80 backdrop-blur-sm flex justify-center items-center z-[100] hidden transition-opacity" onclick="closeImagePopup()">
        <div class="bg-white p-2 rounded-2xl shadow-2xl relative max-w-4xl max-h-[90vh] overflow-auto transform scale-100 transition-transform" onclick="event.stopPropagation()">
            <button class="absolute top-4 right-4 bg-white/50 hover:bg-white text-slate-800 rounded-full p-2 transition" onclick="closeImagePopup()">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            </button>
            <img id="popupImage" src="" alt="Reference Table" class="rounded-xl max-w-full h-auto shadow-inner">
        </div>
    </div>

    <script>
        // Check if Chart is loaded properly
        if (typeof Chart !== 'undefined') {
             // We do NOT register ChartDataLabels globally here to avoid issues with empty charts
             Chart.defaults.font.family = "'Sarabun', sans-serif";
             Chart.defaults.color = '#64748b';
             Chart.defaults.scale.grid.color = '#f1f5f9';
        }

        // Constants
        const hazardData = {
            'light': { density: 0.10, hose: 100 },
            'ordinary1': { density: 0.15, hose: 250 },
            'ordinary2': { density: 0.20, hose: 250 },
            'extra1': { density: 0.30, hose: 500 },
            'extra2': { density: 0.40, hose: 500 }
        };

        const hazardMinDuration = {
            'light': 30, 'ordinary1': 60, 'ordinary2': 60, 'extra1': 90, 'extra2': 120
        };

        window.SQ_M_TO_SQ_FT = 10.7639;
        window.US_GALLONS_TO_CUBIC_METERS = 0.00378541;
        window.DEFAULT_PUMP_RATED_HEAD_PSI = 100;

        let pumpChart = null;
        window.currentTotalFlowGPM = 0;

        const setElementText = (id, text) => {
            const el = document.getElementById(id);
            if (el) el.textContent = text;
        };

        function checkWarnings() {
            const hazardType = document.getElementById('hazard_class').value;
            const durationEl = document.getElementById('duration');
            const duration = parseInt(durationEl.value);
            const warningBox = document.getElementById('warning_box');
            const warningText = document.getElementById('warning_text');

            if (hazardMinDuration[hazardType] > duration) {
                warningText.textContent = `ข้อควรระวัง: สำหรับ ${hazardType}, มาตรฐานแนะนำระยะเวลาอย่างน้อย ${hazardMinDuration[hazardType]} นาที`;
                warningBox.classList.remove('hidden');
                durationEl.classList.add('border-amber-400', 'ring-1', 'ring-amber-400');
            } else {
                warningBox.classList.add('hidden');
                durationEl.classList.remove('border-amber-400', 'ring-1', 'ring-amber-400');
            }
        }

        function calculate() {
            checkWarnings();

            // 1. Get Inputs
            const hazardType = document.getElementById('hazard_class').value;
            const designAreaEl = document.getElementById('design_area');
            const designAreaSqM = parseFloat(designAreaEl.value);
            const duration = parseInt(document.getElementById('duration').value);
            
            const pumpType = document.getElementById('pump_type').value;
            const pumpRatedFlowEl = document.getElementById('pump_rated_flow');
            const systemDemandHeadEl = document.getElementById('system_demand_head');
            
            const pumpRatedFlow = parseFloat(pumpRatedFlowEl.value) || 0;
            const systemDemandHead = parseFloat(systemDemandHeadEl.value) || 0;

            // 2. Validation
            if (!designAreaSqM || designAreaSqM <= 0) {
                designAreaEl.focus();
                designAreaEl.classList.add('border-red-500', 'ring-2', 'ring-red-200');
                setTimeout(() => designAreaEl.classList.remove('border-red-500', 'ring-2', 'ring-red-200'), 2000);
                return;
            }

            // 3. Calculations
            const designAreaSqFt = designAreaSqM * window.SQ_M_TO_SQ_FT;
            const density = hazardData[hazardType].density;
            const hoseAllowance = hazardData[hazardType].hose;

            let sprinklerFlow = designAreaSqFt * density;
            sprinklerFlow = Math.ceil(sprinklerFlow * 100) / 100;
            const totalFlow = sprinklerFlow + hoseAllowance;
            window.currentTotalFlowGPM = totalFlow;

            const tankVolumeGallons = totalFlow * duration;
            const tankVolumeM3 = tankVolumeGallons * window.US_GALLONS_TO_CUBIC_METERS;

            // 4. Update UI
            document.getElementById('results').classList.remove('hidden');
            document.getElementById('result_cards_container').classList.remove('hidden'); // Show cards
            document.getElementById('initial_state_placeholder').classList.add('hidden');

            setElementText('sprinkler_flow', sprinklerFlow.toFixed(2));
            setElementText('hose_allowance', hoseAllowance.toFixed(2));
            setElementText('total_flow', totalFlow.toFixed(2));
            setElementText('tank_volume', tankVolumeM3.toFixed(2));
            setElementText('actual_duration_display', duration);

            setElementText('summary_sprinkler_flow', sprinklerFlow.toFixed(2));
            setElementText('summary_hose_allowance', hoseAllowance.toFixed(2));
            setElementText('summary_total_flow', totalFlow.toFixed(2));
            setElementText('summary_tank_volume', tankVolumeM3.toFixed(2));
            
            const standardPumpSizes = [250, 500, 750, 1000, 1250, 1500, 2000, 2500, 3000, 4000, 5000];
            let recommendedFlow = standardPumpSizes.find(size => size >= totalFlow);
            if (!recommendedFlow) recommendedFlow = Math.ceil(totalFlow / 500) * 500;
            
            setElementText('summary_recommended_pump_flow', "≥ " + recommendedFlow + " GPM");
            setElementText('summary_recommended_pump_flow_card', recommendedFlow);
            setElementText('summary_demand_head_card', systemDemandHead > 0 ? systemDemandHead.toFixed(0) : "---");

            if (pumpRatedFlow > 0 && systemDemandHead > 0) {
                let churnFactor = (pumpType === 'vertical') ? 1.2 : 1.15;
                const maxPressure = systemDemandHead * churnFactor;
                
                setElementText('summary_demand_head_table', systemDemandHead.toFixed(2));
                setElementText('summary_max_pressure', maxPressure.toFixed(2));
                setElementText('summary_estimated_pressure', systemDemandHead.toFixed(2));
                
                generateChart(pumpRatedFlow, systemDemandHead, totalFlow, churnFactor);
            } else {
                if(pumpChart) {
                    pumpChart.destroy();
                    pumpChart = null;
                }
                generateEmptyChart();
            }
        }

        function generateEmptyChart() {
             const ctx = document.getElementById('pumpCurveChart').getContext('2d');
             if (pumpChart) pumpChart.destroy();
             
             pumpChart = new Chart(ctx, {
                type: 'scatter',
                data: { datasets: [] },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        x: { title: { display: true, text: 'Flow (GPM)' }, min: 0, max: 2000 },
                        y: { title: { display: true, text: 'Pressure (PSI)' }, min: 0, max: 200 }
                    },
                    plugins: { legend: { display: false }, title: { display: true, text: 'กรุณากรอกข้อมูลปั๊มเพื่อแสดงกราฟ' } }
                }
             });
        }

        function generateChart(ratedFlow, ratedPressure, demandFlow, churnFactor) {
            const ctx = document.getElementById('pumpCurveChart').getContext('2d');
            
            const churnPressure = ratedPressure * churnFactor;
            const overloadFlow = ratedFlow * 1.5;
            const overloadPressure = ratedPressure * 0.65;

            // Simple Power Curve Interpolation
            const ratioY = (churnPressure - overloadPressure) / (churnPressure - ratedPressure);
            const ratioX = overloadFlow / ratedFlow;
            let n = 2;
            if (ratioY > 0 && ratioX > 0) n = Math.log(ratioY) / Math.log(ratioX);
            const k = (churnPressure - ratedPressure) / Math.pow(ratedFlow, n);

            const curveData = [];
            for (let f = 0; f <= overloadFlow * 1.1; f += (ratedFlow/20)) {
                let p = churnPressure - k * Math.pow(f, n);
                if (p < 0) p = 0;
                curveData.push({x: f, y: p});
            }

            const onClickHandler = (e, activeElements) => {
                if (activeElements.length > 0) {
                    const datasetIndex = activeElements[0].datasetIndex;
                    const index = activeElements[0].index;
                    const datasetLabel = pumpChart.data.datasets[datasetIndex].label;

                    if (datasetLabel === 'Rated Point') {
                         if(window.currentTotalFlowGPM > 0) {
                             document.getElementById('pump_rated_flow').value = window.currentTotalFlowGPM.toFixed(0);
                             calculate();
                         }
                    } else if (datasetLabel === 'Pump Curve') {
                        const point = pumpChart.data.datasets[datasetIndex].data[index];
                        document.getElementById('pump_rated_flow').value = point.x.toFixed(0);
                        document.getElementById('system_demand_head').value = point.y.toFixed(0);
                        calculate();
                    }
                }
            };

            if (pumpChart) pumpChart.destroy();

            pumpChart = new Chart(ctx, {
                type: 'scatter',
                data: {
                    datasets: [
                        {
                            label: 'Pump Curve',
                            data: curveData,
                            showLine: true,
                            borderColor: '#0ea5e9',
                            backgroundColor: 'rgba(14, 165, 233, 0.1)',
                            borderWidth: 3,
                            pointRadius: 3,
                            pointHoverRadius: 6,
                            pointBackgroundColor: 'transparent',
                            pointBorderColor: 'transparent',
                            hitRadius: 10,
                            fill: true,
                            tension: 0.4,
                            datalabels: { display: false }
                        },
                        {
                            label: 'System Demand',
                            data: [{x: demandFlow, y: ratedPressure}],
                            backgroundColor: '#ef4444',
                            pointStyle: 'triangle',
                            pointRadius: 10,
                            pointHoverRadius: 12,
                            datalabels: { align: 'bottom', anchor: 'center', offset: 15 }
                        },
                        {
                            label: 'Rated Point',
                            data: [{x: ratedFlow, y: ratedPressure}],
                            backgroundColor: '#10b981',
                            pointStyle: 'circle',
                            pointRadius: 8,
                            pointHoverRadius: 10,
                            cursor: 'pointer',
                            datalabels: { align: 'top', anchor: 'center', offset: 12 }
                        },
                        {
                            label: 'Churn',
                            data: [{x: 0, y: churnPressure}],
                            backgroundColor: '#b91c1c',
                            pointStyle: 'rect',
                            pointRadius: 6,
                            datalabels: { align: 'bottom', anchor: 'center', offset: 8 }
                        },
                        {
                            label: '150% Point',
                            data: [{x: overloadFlow, y: overloadPressure}],
                            backgroundColor: '#a855f7',
                            pointStyle: 'rectRot',
                            pointRadius: 6,
                            datalabels: { align: 'left', anchor: 'center', offset: 8 }
                        }
                    ]
                },
                plugins: [ChartDataLabels],
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    onClick: onClickHandler,
                    interaction: {
                        mode: 'nearest',
                        axis: 'x',
                        intersect: false
                    },
                    scales: {
                        x: {
                            type: 'linear',
                            title: { display: true, text: 'Flow (GPM)', font: {weight:'bold'} },
                            min: 0
                        },
                        y: {
                            title: { display: true, text: 'Pressure (PSI)', font: {weight:'bold'} },
                            min: 0
                        }
                    },
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            backgroundColor: 'rgba(255, 255, 255, 0.9)',
                            titleColor: '#0f172a',
                            bodyColor: '#334155',
                            borderColor: '#cbd5e1',
                            borderWidth: 1,
                            padding: 10,
                            callbacks: {
                                label: function(context) {
                                    return `${context.dataset.label}: ${context.parsed.x.toFixed(0)} GPM, ${context.parsed.y.toFixed(0)} PSI`;
                                }
                            }
                        },
                        datalabels: {
                            display: true,
                            backgroundColor: '#ffffff',
                            borderRadius: 6,
                            padding: { top: 6, bottom: 6, left: 8, right: 8 },
                            color: '#1e293b',
                            font: { size: 11, weight: 'bold' },
                            borderColor: '#cbd5e1',
                            borderWidth: 1,
                            anchor: 'center', 
                            align: 'center', 
                            clamp: true,
                            formatter: function(value, context) {
                                const gpm = value.x.toFixed(0);
                                const psi = value.y.toFixed(0);
                                if (context.dataset.label === 'Rated Point') return `Rated\n${gpm} GPM\n${psi} PSI`;
                                if (context.dataset.label === 'System Demand') return `Demand\n${gpm} GPM\n${psi} PSI`;
                                if (context.dataset.label === 'Churn') return `Churn\n${psi} PSI`;
                                if (context.dataset.label === '150% Point') return `150%\n${gpm} GPM\n${psi} PSI`;
                                return null;
                            }
                        }
                    }
                }
            });
        }

        function clearData() {
            document.querySelectorAll('input').forEach(input => input.value = '');
            document.getElementById('hazard_class').value = 'light';
            document.getElementById('duration').value = '30';
            document.getElementById('pump_type').value = 'horizontal';
            
            document.getElementById('results').classList.add('hidden');
            document.getElementById('result_cards_container').classList.add('hidden'); // Hide cards
            document.getElementById('initial_state_placeholder').classList.remove('hidden');
            
            if (pumpChart) {
                pumpChart.destroy();
                pumpChart = null;
            }
        }

        function showImagePopup(url) {
            document.getElementById('popupImage').src = url;
            document.getElementById('imagePopupModal').classList.remove('hidden');
        }
        function closeImagePopup() {
            document.getElementById('imagePopupModal').classList.add('hidden');
        }

        document.addEventListener('DOMContentLoaded', () => {
             clearData(); 
        });
    </script>
</body>
</html>
```
```eof
