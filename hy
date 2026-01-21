<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NFPA 13 Calculator</title>
    
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- React & ReactDOM & Babel -->
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    
    <!-- Import Map for Modules -->
    <script type="importmap">
    {
        "imports": {
            "react": "https://esm.sh/react@18.2.0",
            "react-dom/client": "https://esm.sh/react-dom@18.2.0/client",
            "lucide-react": "https://esm.sh/lucide-react@0.263.1"
        }
    }
    </script>

    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        /* Custom scrollbar for better look */
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 3px; }
        ::-webkit-scrollbar-thumb:hover { background: #94a3b8; }
    </style>
</head>
<body class="bg-slate-50 text-slate-900 overflow-hidden">
    <div id="root"></div>

    <script type="text/babel" data-type="module">
        import React, { useState, useEffect, useRef } from 'react';
        import { createRoot } from 'react-dom/client';
        import { 
          Plus, Trash2, Calculator, FileText, Droplets, Upload, Ruler, 
          Maximize, Target, ZoomIn, ZoomOut, Edit3, Check, Info, PlayCircle, 
          Eraser, Magnet, Flame, AlertTriangle, CornerDownRight 
        } from 'lucide-react';

        const pipeSpecs = [
            { nominal: "1", internal: 1.049, color: "#3b82f6" },
            { nominal: "1.25", internal: 1.380, color: "#10b981" },
            { nominal: "1.5", internal: 1.610, color: "#f59e0b" },
            { nominal: "2", internal: 2.067, color: "#ef4444" },
            { nominal: "2.5", internal: 2.469, color: "#8b5cf6" },
            { nominal: "3", internal: 3.068, color: "#ec4899" },
            { nominal: "4", internal: 4.026, color: "#06b6d4" },
            { nominal: "6", internal: 6.065, color: "#14b8a6" },
            { nominal: "8", internal: 7.981, color: "#475569" },
        ];

        const hazardClasses = [
            { id: "LH", label: "Light Hazard", density: 0.10 },
            { id: "OH1", label: "Ordinary Hazard Group 1", density: 0.15 },
            { id: "OH2", label: "Ordinary Hazard Group 2", density: 0.20 },
            { id: "EH1", label: "Extra Hazard Group 1", density: 0.30 },
            { id: "EH2", label: "Extra Hazard Group 2", density: 0.40 },
        ];

        const App = () => {
            const [kFactor, setKFactor] = useState(5.6);
            const [cFactor, setCFactor] = useState(120);
            const [selectedHazard, setSelectedHazard] = useState("EH2");
            const [designDensity, setDesignDensity] = useState(0.40);
            const [areaPerHead, setAreaPerHead] = useState(100);
            const [pdfUrl, setPdfUrl] = useState(null);
            const [isPdf, setIsPdf] = useState(false);
            const [mode, setMode] = useState('pan');
            const [selectedPipeSize, setSelectedPipeSize] = useState("1.25");
            const [scalePoints, setScalePoints] = useState([]);
            const [pixelsPerMeter, setPixelsPerMeter] = useState(null);
            const [realWorldDist, setRealWorldDist] = useState('');
            const [showScaleDialog, setShowScaleDialog] = useState(false);
            const [drawnPipes, setDrawnPipes] = useState([]);
            const [tempPipe, setTempPipe] = useState(null);
            const [placedSprinklers, setPlacedSprinklers] = useState([]);
            const [snapPoint, setSnapPoint] = useState(null);
            const [startSnapInfo, setStartSnapInfo] = useState(null);
            const [transform, setTransform] = useState({ x: 0, y: 0, scale: 1 });
            const [isDragging, setIsDragging] = useState(false);
            const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
            const containerRef = useRef(null);
            const [results, setResults] = useState([]);
            const [totalDemand, setTotalDemand] = useState({ flow: 0, pressure: 0 });
            const [visualNodes, setVisualNodes] = useState([]);
            const [sourceNodeId, setSourceNodeId] = useState(null);

            const safeNum = (val, fallback = 0) => {
                const n = parseFloat(val);
                return isNaN(n) ? fallback : n;
            };
            const safeFixed = (val, dec = 2) => safeNum(val).toFixed(dec);

            // --- Effect to Update Visual Nodes when Pipes Change ---
            useEffect(() => {
                const nodes = {};
                // Use toFixed to ensure precision consistency
                const getNodeKey = (pt) => `${pt.x.toFixed(1)},${pt.y.toFixed(1)}`;
                const getOrCreateNode = (pt) => {
                const key = getNodeKey(pt);
                if (!nodes[key]) nodes[key] = { id: key, x: pt.x, y: pt.y, degree: 0 };
                return nodes[key];
                };

                drawnPipes.forEach(p => {
                const n1 = getOrCreateNode(p.start);
                const n2 = getOrCreateNode(p.end);
                n1.degree += 1;
                n2.degree += 1;
                });
                setVisualNodes(Object.values(nodes));
            }, [drawnPipes]);

            const handleHazardChange = (e) => {
                const hazardId = e.target.value;
                setSelectedHazard(hazardId);
                const hazard = hazardClasses.find(h => h.id === hazardId);
                if (hazard) setDesignDensity(hazard.density);
            };

            const handleFileChange = (e) => {
                const file = e.target.files[0];
                if (!file) return;
                if (pdfUrl && pdfUrl.startsWith('blob:')) URL.revokeObjectURL(pdfUrl);
                setPdfUrl(URL.createObjectURL(file));
                setIsPdf(file.type === "application/pdf");
                setScalePoints([]);
                setDrawnPipes([]);
                setPlacedSprinklers([]);
                setResults([]);
                setVisualNodes([]);
                setTotalDemand({ flow: 0, pressure: 0 });
                setTransform({ x: 0, y: 0, scale: 1 });
                setMode('pan');
                setSourceNodeId(null);
            };

            const getCanvasCoords = (e) => {
                if (!containerRef.current) return { x: 0, y: 0 };
                const rect = containerRef.current.getBoundingClientRect();
                return {
                x: (e.clientX - rect.left - transform.x) / transform.scale,
                y: (e.clientY - rect.top - transform.y) / transform.scale
                };
            };

            const projectPointToSegment = (P, A, B) => {
                const distAB2 = Math.pow(B.x - A.x, 2) + Math.pow(B.y - A.y, 2);
                if (distAB2 === 0) return A;
                let t = ((P.x - A.x) * (B.x - A.x) + (P.y - A.y) * (B.y - A.y)) / distAB2;
                t = Math.max(0, Math.min(1, t));
                return { x: A.x + t * (B.x - A.x), y: A.y + t * (B.y - A.y) };
            };

            const getSnappedCoords = (rawCoords) => {
                if (mode !== 'draw' && mode !== 'sprinkler') return { coords: rawCoords, isSnapped: false, snapType: null, snapTarget: null };

                const snapThreshold = 15 / transform.scale;
                let closestPoint = null;
                let minDistance = Infinity;
                let snapType = null;
                let snapTarget = null;

                // 1. Check Endpoints (Nodes)
                drawnPipes.forEach(pipe => {
                [pipe.start, pipe.end].forEach(pt => {
                    const dist = Math.sqrt(Math.pow(pt.x - rawCoords.x, 2) + Math.pow(pt.y - rawCoords.y, 2));
                    if (dist < snapThreshold && dist < minDistance) {
                    minDistance = dist;
                    closestPoint = pt;
                    snapType = 'node';
                    snapTarget = pipe;
                    }
                });
                });

                // 2. Check Edges
                if (!closestPoint) {
                drawnPipes.forEach(pipe => {
                    const projected = projectPointToSegment(rawCoords, pipe.start, pipe.end);
                    const dist = Math.sqrt(Math.pow(projected.x - rawCoords.x, 2) + Math.pow(projected.y - rawCoords.y, 2));
                    if (dist < snapThreshold && dist < minDistance) {
                    minDistance = dist;
                    closestPoint = projected;
                    snapType = 'edge';
                    snapTarget = pipe;
                    }
                });
                }

                if (closestPoint) return { coords: closestPoint, isSnapped: true, snapType, snapTarget };
                return { coords: rawCoords, isSnapped: false, snapType: null, snapTarget: null };
            };

            // Function to split a pipe at a specific point
            const splitPipeAtPoint = (pipes, targetPipe, splitPoint) => {
                const remainingPipes = pipes.filter(p => p.id !== targetPipe.id);
                const dist1 = Math.sqrt(Math.pow(splitPoint.x - targetPipe.start.x, 2) + Math.pow(splitPoint.y - targetPipe.start.y, 2));
                const dist2 = Math.sqrt(Math.pow(targetPipe.end.x - splitPoint.x, 2) + Math.pow(targetPipe.end.y - splitPoint.y, 2));

                const newSegments = [];
                if (dist1 > 0.1) {
                newSegments.push({
                    ...targetPipe,
                    id: Date.now() + Math.random(),
                    end: splitPoint,
                    pixelLength: dist1
                });
                }
                if (dist2 > 0.1) {
                newSegments.push({
                    ...targetPipe,
                    id: Date.now() + Math.random() + 1,
                    start: splitPoint,
                    pixelLength: dist2
                });
                }
                return [...remainingPipes, ...newSegments];
            };

            const handleMouseDown = (e) => {
                if (showScaleDialog) return;
                const rawCoords = getCanvasCoords(e);
                const snapInfo = getSnappedCoords(rawCoords);
                const { coords, isSnapped, snapType, snapTarget } = snapInfo;

                if (mode === 'pan') {
                setIsDragging(true);
                setDragStart({ x: e.clientX - transform.x, y: e.clientY - transform.y });
                } else if (mode === 'scale') {
                setIsDragging(true);
                setScalePoints([coords, coords]);
                } else if (mode === 'draw') {
                setIsDragging(true);
                setStartSnapInfo(isSnapped ? { type: snapType, target: snapTarget, coords: coords } : null);
                setTempPipe({ start: coords, end: coords, size: selectedPipeSize });
                }
            };

            const handleMouseMove = (e) => {
                if (showScaleDialog) return;
                const rawCoords = getCanvasCoords(e);
                const { coords, isSnapped } = getSnappedCoords(rawCoords);
                setSnapPoint(isSnapped ? coords : null);

                if (isDragging) {
                if (mode === 'pan') {
                    setTransform(prev => ({
                    ...prev,
                    x: e.clientX - dragStart.x,
                    y: e.clientY - dragStart.y
                    }));
                } else if (mode === 'scale') {
                    setScalePoints(prev => [prev[0], rawCoords]);
                } else if (mode === 'draw') {
                    setTempPipe(prev => ({ ...prev, end: coords }));
                }
                }
            };

            const handleMouseUp = () => {
                if (showScaleDialog) return;

                if (mode === 'scale' && isDragging) {
                const dx = scalePoints[1].x - scalePoints[0].x;
                const dy = scalePoints[1].y - scalePoints[0].y;
                const dist = Math.sqrt(dx * dx + dy * dy);
                if (dist > 5) {
                    setShowScaleDialog(true);
                    setRealWorldDist('');
                    setIsDragging(false);
                    return;
                } else {
                    setScalePoints([]);
                }
                } else if (mode === 'draw' && isDragging && tempPipe) {
                const endSnapInfo = getSnappedCoords(tempPipe.end);
                const finalEnd = endSnapInfo.isSnapped ? endSnapInfo.coords : tempPipe.end;

                const dx = finalEnd.x - tempPipe.start.x;
                const dy = finalEnd.y - tempPipe.start.y;
                const pixelLen = Math.sqrt(dx * dx + dy * dy);

                if (pixelLen > 2) {
                    let nextPipes = [...drawnPipes];
                    let actualStart = tempPipe.start;
                    let actualEnd = finalEnd;

                    if (startSnapInfo && startSnapInfo.type === 'edge' && startSnapInfo.target) {
                    const targetPipe = nextPipes.find(p => p.id === startSnapInfo.target.id);
                    if (targetPipe) {
                        nextPipes = splitPipeAtPoint(nextPipes, targetPipe, startSnapInfo.coords);
                        actualStart = startSnapInfo.coords;
                    }
                    }

                    if (endSnapInfo.isSnapped && endSnapInfo.snapType === 'edge' && endSnapInfo.snapTarget) {
                    const targetPipe = nextPipes.find(p => p.id === endSnapInfo.snapTarget.id);
                    if (targetPipe) {
                        nextPipes = splitPipeAtPoint(nextPipes, targetPipe, endSnapInfo.coords);
                        actualEnd = endSnapInfo.coords;
                    }
                    }

                    nextPipes.push({
                    id: Date.now() + Math.random(),
                    start: actualStart,
                    end: actualEnd,
                    size: tempPipe.size,
                    pixelLength: pixelLen
                    });
                    setDrawnPipes(nextPipes);
                }
                setTempPipe(null);
                setStartSnapInfo(null);
                }
                setIsDragging(false);
            };

            const handleCanvasClick = (e) => {
                if (showScaleDialog) return;
                const rawCoords = getCanvasCoords(e);
                const { coords, isSnapped, snapType, snapTarget } = getSnappedCoords(rawCoords);

                if (mode === 'sprinkler') {
                setPlacedSprinklers([...placedSprinklers, { ...coords, id: Date.now() }]);
                if (isSnapped && snapType === 'edge' && snapTarget) {
                    const newPipes = splitPipeAtPoint(drawnPipes, snapTarget, coords);
                    setDrawnPipes(newPipes);
                }
                } else if (mode === 'delete') {
                const clickThreshold = 10 / transform.scale;
                const pipeToDelete = drawnPipes.find(pipe => {
                    const dist = distanceToSegment(rawCoords, pipe.start, pipe.end);
                    return dist < clickThreshold;
                });

                if (pipeToDelete) {
                    setDrawnPipes(drawnPipes.filter(p => p.id !== pipeToDelete.id));
                } else {
                    const sprinklerToDelete = placedSprinklers.find(s => {
                    const dist = Math.sqrt(Math.pow(s.x - rawCoords.x, 2) + Math.pow(s.y - rawCoords.y, 2));
                    return dist < clickThreshold;
                    });
                    if (sprinklerToDelete) {
                    setPlacedSprinklers(placedSprinklers.filter(s => s.id !== sprinklerToDelete.id));
                    }
                }
                }
            };

            const applyScale = () => {
                if (scalePoints.length < 2) return;
                const dx = scalePoints[1].x - scalePoints[0].x;
                const dy = scalePoints[1].y - scalePoints[0].y;
                const pixelDist = Math.sqrt(dx * dx + dy * dy);
                const rDist = parseFloat(realWorldDist);

                if (pixelDist > 0 && rDist > 0) {
                setPixelsPerMeter(pixelDist / rDist);
                setMode('pan');
                setShowScaleDialog(false);
                setScalePoints([]);
                } else {
                alert("กรุณาระบุระยะทางที่ถูกต้อง");
                }
            };

            const adjustZoom = (delta) => {
                if (!containerRef.current) return;
                const zoomStep = 0.15;
                const oldScale = transform.scale;
                const newScale = Math.min(Math.max(oldScale + (delta > 0 ? zoomStep : -zoomStep), 0.1), 10);

                const rect = containerRef.current.getBoundingClientRect();
                const centerX = rect.width / 2;
                const centerY = rect.height / 2;

                const worldX = (centerX - transform.x) / oldScale;
                const worldY = (centerY - transform.y) / oldScale;

                const newX = centerX - worldX * newScale;
                const newY = centerY - worldY * newScale;

                setTransform({ x: newX, y: newY, scale: newScale });
            };

            const distanceToSegment = (P, A, B) => {
                const distAB2 = Math.pow(B.x - A.x, 2) + Math.pow(B.y - A.y, 2);
                if (distAB2 === 0) return Math.sqrt(Math.pow(P.x - A.x, 2) + Math.pow(P.y - A.y, 2));
                let t = ((P.x - A.x) * (B.x - A.x) + (P.y - A.y) * (B.y - A.y)) / distAB2;
                t = Math.max(0, Math.min(1, t));
                return Math.sqrt(Math.pow(P.x - (A.x + t * (B.x - A.x)), 2) + Math.pow(P.y - (A.y + t * (B.y - A.y)), 2));
            };

            const calculateLoss = (Q, L_ft, d_in, C) => {
                if (Q <= 0 || L_ft <= 0) return 0;
                return (4.52 * Math.pow(Q, 1.85) * L_ft) / (Math.pow(C, 1.85) * Math.pow(d_in, 4.87));
            };

            const handleCalculate = () => {
                if (!pixelsPerMeter) {
                alert("กรุณากำหนดสเกล (Set Scale) ก่อนคำนวณ");
                return;
                }
                if (drawnPipes.length === 0) {
                alert("กรุณาวาดท่ออย่างน้อย 1 เส้น");
                return;
                }

                const M_TO_FT = 3.28084;
                const K = safeNum(kFactor, 5.6);
                const C = safeNum(cFactor, 120);
                const RISER_NIPPLE_FT = 0.1 * M_TO_FT;
                const NIPPLE_ID = 1.049;
                const density = safeNum(designDensity, 0.40);
                const areaFt2 = safeNum(areaPerHead, 100);

                const qMinHead = density * areaFt2;
                const minP_Req = Math.pow(qMinHead / K, 2);
                const startPressureReq = Math.max(7, minP_Req);

                // 1. Build Graph
                const nodes = {};
                const getNodeKey = (pt) => `${pt.x.toFixed(1)},${pt.y.toFixed(1)}`; // Consistent precision
                const getOrCreateNode = (pt) => {
                const key = getNodeKey(pt);
                if (!nodes[key]) nodes[key] = { id: key, x: pt.x, y: pt.y, connections: [], heads: [] };
                return nodes[key];
                };

                drawnPipes.forEach(p => {
                const n1 = getOrCreateNode(p.start);
                const n2 = getOrCreateNode(p.end);
                const spec = pipeSpecs.find(s => s.nominal === p.size) || pipeSpecs[0];
                const edge = {
                    id: p.id,
                    u: n1.id,
                    v: n2.id,
                    pipe: p,
                    size: p.size,
                    heads: [], 
                    d_in: spec.internal,
                    len_ft: (p.pixelLength / pixelsPerMeter) * M_TO_FT,
                    flow: 0,
                    loss: 0,
                    velocity: 0,
                    headsAssigned: []
                };
                n1.connections.push({ target: n2.id, edge });
                n2.connections.push({ target: n1.id, edge });
                });

                // 2. Assign Sprinklers
                const tolerance = 5 / transform.scale;
                placedSprinklers.forEach(s => {
                let assigned = false;
                for (const nodeId in nodes) {
                    const node = nodes[nodeId];
                    const dist = Math.sqrt(Math.pow(s.x - node.x, 2) + Math.pow(s.y - node.y, 2));
                    if (dist < tolerance) {
                    node.heads.push(s);
                    assigned = true;
                    break;
                    }
                }
                });

                // 3. Determine Source (Root of Tree)
                let sourceId = null;
                let maxDia = -1;
                const allNodes = Object.values(nodes);

                // Find endpoints (nodes with degree 1)
                const endPoints = allNodes.filter(n => n.connections.length === 1);

                if (endPoints.length > 0) {
                endPoints.forEach(n => {
                    const pipeSize = parseFloat(n.connections[0].edge.size);
                    if (pipeSize > maxDia) {
                    maxDia = pipeSize;
                    sourceId = n.id;
                    }
                });
                }

                // Fallback: Max diameter node if no endpoints (Grid/Loop system)
                if (!sourceId && allNodes.length > 0) {
                    // In a loop, any node with max pipe diameter is a candidate. 
                    // We pick the first one we find to ensure stability.
                    allNodes.forEach(n => {
                        const localMax = n.connections.reduce((m, c) => Math.max(m, parseFloat(c.edge.size)), 0);
                        if (localMax > maxDia) {
                            maxDia = localMax;
                            sourceId = n.id;
                        }
                    });
                    // Ultimate fallback
                    if (!sourceId) sourceId = allNodes[0].id;
                }

                setSourceNodeId(sourceId);

                // 4. Traverse Tree BFS (Build Tree Structure from Source)
                const parentMap = {}; 
                const processingOrder = []; 
                const visited = new Set([sourceId]);
                const queue = [sourceId];

                while(queue.length > 0) {
                const uId = queue.shift();
                processingOrder.push(uId);
                const uNode = nodes[uId];
                
                if(uNode && uNode.connections) {
                    uNode.connections.forEach(conn => {
                    if (!visited.has(conn.target)) {
                        visited.add(conn.target);
                        parentMap[conn.target] = { parentId: uId, edge: conn.edge };
                        queue.push(conn.target);
                    }
                    });
                }
                }

                const nodeReqP = {};
                const nodeTotalQ = {};
                Object.keys(nodes).forEach(k => {
                nodeReqP[k] = 0;
                nodeTotalQ[k] = 0;
                });

                const calcReport = [];

                // 5. Backward Pass (Calculate Demand)
                for (let i = processingOrder.length - 1; i >= 0; i--) {
                const uId = processingOrder[i];
                let maxP_RequiredAtU = 0;
                let totalQ_AtU = 0;
                
                const uNode = nodes[uId];
                if(!uNode) continue;

                // Identify children in the spanning tree
                const childConnections = uNode.connections.filter(conn => parentMap[conn.target]?.parentId === uId);

                // Pass 1: Determine Max Pressure required at this node from downstream
                childConnections.forEach(child => {
                    const vId = child.target;
                    const edge = child.edge;
                    const qChild = nodeTotalQ[vId] || 0;
                    const pChild = nodeReqP[vId] || 0;

                    if (qChild > 0 || pChild > 0) {
                    const loss = calculateLoss(qChild, edge.len_ft, edge.d_in, C);
                    const pReqUpstream = pChild + loss;
                    maxP_RequiredAtU = Math.max(maxP_RequiredAtU, pReqUpstream);
                    }
                });

                // Add Heads directly at Node U
                let hasActiveHead = uNode.heads.length > 0;
                if (hasActiveHead) {
                    if (maxP_RequiredAtU < startPressureReq) maxP_RequiredAtU = startPressureReq;
                    
                    uNode.heads.forEach(() => {
                    let pHead = maxP_RequiredAtU;
                    // Simple riser nipple loss calc
                    for(let k=0; k<2; k++) {
                        let q = K * Math.sqrt(pHead > 0 ? pHead : 0);
                        let lossNip = calculateLoss(q, RISER_NIPPLE_FT, NIPPLE_ID, C);
                        pHead = maxP_RequiredAtU - lossNip;
                    }
                    if(pHead < 0) pHead = 0;
                    totalQ_AtU += K * Math.sqrt(pHead);
                    });
                }

                // Pass 2: Balance Flow from Branches based on Max Pressure
                childConnections.forEach(child => {
                    const vId = child.target;
                    const edge = child.edge;
                    let qBranch = nodeTotalQ[vId] || 0;
                    const pChildReq = nodeReqP[vId] || 0;
                    
                    // Base loss before balancing
                    const lossBase = calculateLoss(qBranch, edge.len_ft, edge.d_in, C);
                    const pBranchReqAtU = pChildReq + lossBase;

                    // --- FIX FOR LOOPS/ZERO DEMAND ---
                    // If pBranchReqAtU is near zero, K-factor blows up (NaN). 
                    // We only balance if there is actual demand downstream.
                    if (maxP_RequiredAtU > pBranchReqAtU && pBranchReqAtU > 0.01 && qBranch > 0) {
                    // Adjust flow to match the higher pressure at Node U
                    // K_branch = Q / sqrt(P_req)
                    const kBranch = qBranch / Math.sqrt(pBranchReqAtU);
                    // New Q = K_branch * sqrt(P_available)
                    qBranch = kBranch * Math.sqrt(maxP_RequiredAtU);
                    }

                    edge.flow = qBranch;
                    edge.loss = calculateLoss(qBranch, edge.len_ft, edge.d_in, C);
                    edge.velocity = (0.4085 * qBranch) / Math.pow(edge.d_in, 2);
                    edge.flowDir = (edge.u === uId) ? 'u->v' : 'v->u';
                    
                    totalQ_AtU += qBranch;

                    if (qBranch > 0 || (edge.flow > 0)) {
                    calcReport.push({
                        pipeId: edge.id,
                        id: `Pipe ${edge.size}"`,
                        size: edge.size,
                        lengthM: edge.len_ft / M_TO_FT,
                        flow: qBranch,
                        loss: edge.loss,
                        pressure: maxP_RequiredAtU,
                        velocity: edge.velocity,
                        addedFlow: 0,
                        headCount: 0,
                        flowDir: edge.flowDir
                    });
                    }
                });

                nodeReqP[uId] = maxP_RequiredAtU;
                nodeTotalQ[uId] = totalQ_AtU;
                }

                setResults(calcReport.reverse());
                setTotalDemand({ flow: nodeTotalQ[sourceId] || 0, pressure: nodeReqP[sourceId] || 0 });
            };

            // Calculate Layout for Tags to avoid collision
            const getTagLayout = () => {
                if (!results || results.length === 0) return [];
                
                const layout = [];
                const occupiedRects = [];
                const tagW = 90 / transform.scale;
                const tagH = 44 / transform.scale;
                const padding = 10 / transform.scale;

                drawnPipes.forEach(pipe => {
                const res = results.find(r => r.pipeId === pipe.id);
                if (!res || res.flow <= 0) return;

                // Base Position calculation
                let startX = pipe.start.x, startY = pipe.start.y;
                let endX = pipe.end.x, endY = pipe.end.y;

                if (res.flowDir === 'v->u') {
                    startX = pipe.end.x; startY = pipe.end.y;
                    endX = pipe.start.x; endY = pipe.start.y;
                }

                const midX = (startX + endX) / 2;
                const midY = (startY + endY) / 2;
                const pdx = endX - startX;
                const pdy = endY - startY;
                const plen = Math.sqrt(pdx*pdx + pdy*pdy);
                
                const offsetDist = 60 / transform.scale;
                let offX = plen > 0 ? (-pdy / plen) * offsetDist : 0;
                let offY = plen > 0 ? (pdx / plen) * offsetDist : 0;

                // Force Right for Vertical
                if (Math.abs(pdy) > Math.abs(pdx)) {
                    if (offX < 0) { offX = -offX; offY = -offY; }
                }

                let tagX = midX + offX;
                let tagY = midY + offY;

                // Collision Avoidance (Stacking Outwards)
                let attempts = 0;
                while(attempts < 10) {
                    let collision = false;
                    for(let rect of occupiedRects) {
                    if (
                        tagX - tagW/2 < rect.x + rect.w &&
                        tagX + tagW/2 > rect.x &&
                        tagY - tagH/2 < rect.y + rect.h &&
                        tagY + tagH/2 > rect.y
                    ) {
                        collision = true;
                        break;
                    }
                    }
                    if (!collision) break;
                    
                    // Push out further along the normal vector
                    const pushStep = (tagH + padding);
                    const lenOff = Math.sqrt(offX*offX + offY*offY) || 1;
                    const uX = offX / lenOff;
                    const uY = offY / lenOff;
                    tagX += uX * pushStep;
                    tagY += uY * pushStep;
                    attempts++;
                }

                occupiedRects.push({ x: tagX - tagW/2, y: tagY - tagH/2, w: tagW, h: tagH });
                layout.push({
                    id: pipe.id,
                    tagX, tagY, midX, midY, // For leader line
                    res
                });
                });
                return layout;
            };

            const tagLayout = getTagLayout();

            return (
                <div className="flex h-screen w-full bg-slate-50 overflow-hidden font-sans select-none">
                
                {/* Side Panel */}
                <div className="w-80 bg-white border-r border-slate-200 flex flex-col shadow-xl z-20">
                    <div className="p-4 bg-slate-900 text-white flex justify-between items-center">
                    <h1 className="font-bold text-lg flex items-center gap-2">
                        <Flame size={20} className="text-orange-500" />
                        NFPA 13 Calc
                    </h1>
                    <label className="cursor-pointer bg-slate-700 hover:bg-slate-600 p-2 rounded transition-colors" title="Import PDF/Image">
                        <input type="file" accept="application/pdf,image/*" onChange={handleFileChange} className="hidden" />
                        <Upload size={16} />
                    </label>
                    </div>

                    <div className="flex-1 overflow-y-auto p-4 space-y-6">
                    
                    <div className="space-y-3">
                        <div className="flex justify-between items-center">
                            <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Plan File</h3>
                            {pdfUrl && <Check size={14} className="text-emerald-500"/>}
                        </div>
                    </div>

                    {/* Hazard Classification Selection */}
                    <div className="space-y-2">
                        <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Hazard Classification</h3>
                        <select 
                            value={selectedHazard} 
                            onChange={handleHazardChange}
                            className="w-full p-2 bg-slate-100 border-none rounded text-sm font-medium outline-none focus:ring-2 focus:ring-blue-500"
                        >
                            {hazardClasses.map(h => (
                            <option key={h.id} value={h.id}>{h.label}</option>
                            ))}
                        </select>
                        <div className="flex justify-between text-xs text-slate-500 px-1">
                            <span>Density: <span className="font-bold text-slate-800">{designDensity.toFixed(2)}</span> gpm/ft²</span>
                        </div>
                        <div className="flex justify-between items-center text-xs text-slate-500 px-1 pt-2">
                            <span>Area/Head:</span>
                            <div className="flex items-center gap-1">
                            <input 
                                type="number" 
                                value={areaPerHead} 
                                onChange={(e) => setAreaPerHead(parseFloat(e.target.value))} 
                                className="w-12 text-right font-bold text-slate-800 border-b border-slate-300 outline-none" 
                            />
                            <span>ft²</span>
                            </div>
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                        <label className="text-[10px] font-bold text-slate-400 uppercase block mb-1">K-Factor</label>
                        <input type="number" value={kFactor} onChange={(e) => setKFactor(e.target.value)} className="w-full bg-transparent font-bold text-sm outline-none"/>
                        </div>
                        <div className="bg-slate-50 p-3 rounded-lg border border-slate-100">
                        <label className="text-[10px] font-bold text-slate-400 uppercase block mb-1">C-Factor</label>
                        <input type="number" value={cFactor} onChange={(e) => setCFactor(e.target.value)} className="w-full bg-transparent font-bold text-sm outline-none"/>
                        </div>
                    </div>

                    <div className="space-y-2">
                        <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Pipe Size (ASTM Sch.40)</h3>
                        <div className="grid grid-cols-4 gap-2">
                            {pipeSpecs.map(spec => (
                            <button
                                key={spec.nominal}
                                onClick={() => { setMode('draw'); setSelectedPipeSize(spec.nominal); }}
                                className={`py-2 px-1 rounded-lg text-[10px] font-bold border-2 transition-all flex flex-col items-center gap-1 ${
                                    mode === 'draw' && selectedPipeSize === spec.nominal 
                                    ? 'border-slate-900 bg-slate-900 text-white' 
                                    : 'border-slate-100 bg-white text-slate-600 hover:border-slate-300'
                                }`}
                            >
                                <div className="w-2 h-2 rounded-full" style={{backgroundColor: spec.color}}></div>
                                {spec.nominal}"
                            </button>
                            ))}
                        </div>
                    </div>

                    <div className="bg-slate-100 p-4 rounded-xl space-y-2">
                        <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider flex justify-between">
                            System Demand
                            {pixelsPerMeter ? (
                            <span className="text-[10px] bg-emerald-100 text-emerald-600 px-2 py-0.5 rounded-full">Scale: {safeFixed(pixelsPerMeter, 2)} px/m</span>
                            ) : <span className="text-[10px] bg-red-100 text-red-500 px-2 py-0.5 rounded-full">No Scale</span>}
                        </h3>
                        <div className="flex justify-between items-baseline">
                            <span className="text-slate-500 text-sm">Total Flow</span>
                            <span className="text-xl font-black text-slate-800">{safeFixed(totalDemand.flow, 1)} <span className="text-xs font-normal text-slate-500">GPM</span></span>
                        </div>
                        <div className="flex justify-between items-baseline">
                            <span className="text-slate-500 text-sm">Total Pressure</span>
                            <span className="text-xl font-black text-slate-800">{safeFixed(totalDemand.pressure, 2)} <span className="text-xs font-normal text-slate-500">PSI</span></span>
                        </div>
                    </div>

                    </div>
                </div>

                {/* Main Canvas Area */}
                <div className="flex-1 relative overflow-hidden bg-slate-200 cursor-crosshair">
                    
                    {/* Toolbar */}
                    <div className="absolute top-4 left-1/2 transform -translate-x-1/2 bg-slate-900/90 backdrop-blur-md p-2 rounded-2xl flex gap-2 shadow-2xl z-30 border border-slate-700">
                    <button onClick={() => adjustZoom(-1)} className="p-2 text-slate-400 hover:text-white transition-all"><ZoomOut size={18}/></button>
                    <span className="text-xs font-bold text-slate-300 flex items-center px-2 w-12 justify-center select-none">
                        {Math.round(transform.scale * 100)}%
                    </span>
                    <button onClick={() => adjustZoom(1)} className="p-2 text-slate-400 hover:text-white transition-all"><ZoomIn size={18}/></button>
                    <div className="w-px bg-slate-700 mx-1"></div>
                    <button onClick={() => setMode('pan')} className={`p-2 rounded-md transition-all ${mode === 'pan' ? 'bg-slate-600 text-white' : 'text-slate-400 hover:text-white'}`} title="Pan"> <Maximize size={18} /> </button>
                    <button onClick={() => { setMode('scale'); setScalePoints([]); }} className={`p-2 rounded-md transition-all ${mode === 'scale' ? 'bg-red-600 text-white' : 'text-slate-400 hover:text-white'}`} title="Set Scale"> <Ruler size={18} /> </button>
                    <button onClick={() => setMode('sprinkler')} className={`p-2 rounded-md transition-all ${mode === 'sprinkler' ? 'bg-blue-600 text-white' : 'text-slate-400 hover:text-white'}`} title="Place Sprinkler"> <Droplets size={18} /> </button>
                    <button onClick={() => setMode('draw')} className={`p-2 rounded-md transition-all ${mode === 'draw' ? 'bg-emerald-600 text-white' : 'text-slate-400 hover:text-white'}`} title="Draw Pipe"> <Edit3 size={18} /> </button>
                    <button onClick={() => setMode('delete')} className={`p-2 rounded-md transition-all ${mode === 'delete' ? 'bg-orange-500 text-white' : 'text-slate-400 hover:text-white'}`} title="Delete"> <Trash2 size={18} /> </button>
                    
                    <div className="w-px bg-slate-700 mx-1"></div>
                    <button 
                        onClick={handleCalculate}
                        className="px-4 py-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg text-xs font-bold uppercase tracking-wider hover:from-blue-500 hover:to-indigo-500 shadow-lg flex items-center gap-2"
                    >
                        <Calculator size={14} /> Calculate
                    </button>
                    <button 
                        onClick={() => {
                            setDrawnPipes([]);
                            setPlacedSprinklers([]);
                            // setPixelsPerMeter(null); // Keep Scale
                            setResults([]);
                            setTotalDemand({ flow: 0, pressure: 0 });
                            setVisualNodes([]);
                            setSourceNodeId(null);
                        }}
                        className="text-[10px] font-black uppercase text-red-400 hover:text-red-300 transition-colors ml-2"
                    >
                        Clear All
                    </button>
                    </div>

                    {/* Viewport Area */}
                    <div 
                    ref={containerRef}
                    className="w-full h-full relative overflow-hidden"
                    onMouseDown={handleMouseDown}
                    onMouseMove={handleMouseMove}
                    onMouseUp={handleMouseUp}
                    onMouseLeave={handleMouseUp}
                    onClick={handleCanvasClick}
                    onContextMenu={(e) => e.preventDefault()}
                    >
                    <div 
                        style={{ 
                        transform: `translate(${transform.x}px, ${transform.y}px) scale(${transform.scale})`,
                        transformOrigin: '0 0',
                        willChange: 'transform'
                        }}
                        className="absolute top-0 left-0 w-full h-full"
                    >
                        {pdfUrl ? (
                            <>
                            {isPdf ? <embed src={`${pdfUrl}#toolbar=0&navpanes=0&scrollbar=0`} className="absolute pointer-events-none opacity-80" style={{ width: '2000px', height: '2000px' }} /> : <img src={pdfUrl} className="absolute pointer-events-none opacity-60" alt="Plan" />}
                            </>
                        ) : (
                            <div className="absolute top-10 left-10 text-slate-300 font-bold text-6xl pointer-events-none opacity-20">
                            อัปโหลดไฟล์เพื่อเริ่มใช้งาน
                            </div>
                        )}

                        {/* Grid for reference (optional) */}
                        {/* <div className="absolute inset-0 bg-[url('https://grainy-gradients.vercel.app/noise.svg')] opacity-10 pointer-events-none"></div> */}

                        {/* Render Pipes */}
                        <svg className="absolute top-0 left-0 overflow-visible pointer-events-none" width="1" height="1">
                        {drawnPipes.map(pipe => {
                            const spec = pipeSpecs.find(s => s.nominal === pipe.size) || pipeSpecs[0];
                            const isSourcePipe = false; // Logic simplified
                            return (
                            <g key={pipe.id}>
                                {/* Outer casing */}
                                <line 
                                x1={pipe.start.x} y1={pipe.start.y} 
                                x2={pipe.end.x} y2={pipe.end.y} 
                                stroke="white" 
                                strokeWidth={6} 
                                strokeLinecap="round"
                                />
                                {/* Core pipe */}
                                <line 
                                x1={pipe.start.x} y1={pipe.start.y} 
                                x2={pipe.end.x} y2={pipe.end.y} 
                                stroke={spec.color} 
                                strokeWidth={4} 
                                strokeLinecap="round"
                                />
                            </g>
                            );
                        })}

                        {/* Temp Pipe while drawing */}
                        {tempPipe && (
                            <line 
                            x1={tempPipe.start.x} y1={tempPipe.start.y} 
                            x2={tempPipe.end.x} y2={tempPipe.end.y} 
                            stroke={pipeSpecs.find(s => s.nominal === tempPipe.size)?.color || 'black'} 
                            strokeWidth={4} 
                            strokeDasharray="10,5"
                            strokeLinecap="round"
                            opacity={0.6}
                            />
                        )}

                        {/* Scale Line */}
                        {scalePoints.length === 2 && (
                            <line 
                                x1={scalePoints[0].x} y1={scalePoints[0].y} 
                                x2={scalePoints[1].x} y2={scalePoints[1].y} 
                                stroke="#dc2626" 
                                strokeWidth={2} 
                                strokeDasharray="5,5"
                            />
                        )}

                        {/* Tag Leaders */}
                        {tagLayout.map(tag => (
                            <line 
                            key={`leader-${tag.id}`}
                            x1={tag.midX} y1={tag.midY}
                            x2={tag.tagX} y2={tag.tagY}
                            stroke="#94a3b8"
                            strokeWidth={1}
                            opacity={0.5}
                            />
                        ))}
                        </svg>

                        {/* Render Nodes (Joints) */}
                        {visualNodes.map(n => (
                        <div 
                            key={n.id}
                            className={`absolute w-3 h-3 -ml-1.5 -mt-1.5 rounded-full border-2 border-white shadow-sm flex items-center justify-center
                            ${sourceNodeId === n.id ? 'bg-blue-600 w-5 h-5 -ml-2.5 -mt-2.5 z-10' : 'bg-slate-400'}
                            `}
                            style={{ left: n.x, top: n.y }}
                        >
                            {sourceNodeId === n.id && <span className="text-[8px] text-white font-bold">S</span>}
                        </div>
                        ))}

                        {/* Render Sprinklers */}
                        {placedSprinklers.map(s => (
                        <div 
                            key={s.id}
                            className="absolute w-5 h-5 -ml-2.5 -mt-2.5 rounded-full bg-blue-500 border-2 border-white shadow-md flex items-center justify-center z-10"
                            style={{ left: s.x, top: s.y }}
                        >
                            <div className="w-1.5 h-1.5 bg-white rounded-full"></div>
                        </div>
                        ))}

                        {/* Snap Indicator */}
                        {snapPoint && (
                        <div 
                            className="absolute w-6 h-6 -ml-3 -mt-3 rounded-full border-2 border-emerald-400 bg-emerald-400/20 animate-pulse pointer-events-none z-50"
                            style={{ left: snapPoint.x, top: snapPoint.y }}
                        ></div>
                        )}

                        {/* Render Tags */}
                        {tagLayout.map(tag => (
                        <div
                            key={`tag-${tag.id}`}
                            className="absolute bg-white/95 backdrop-blur shadow-sm border border-slate-200 rounded px-2 py-1 flex flex-col items-start gap-0.5 min-w-[80px]"
                            style={{ 
                                left: tag.tagX, 
                                top: tag.tagY,
                                transform: 'translate(-50%, -50%)',
                                fontSize: `${10}px`
                            }}
                        >
                            <div className="font-bold text-slate-700 leading-none">{tag.res.size}" - {safeFixed(tag.res.lengthM, 2)}m</div>
                            <div className="text-slate-500 leading-none">Q: {safeFixed(tag.res.flow, 1)}</div>
                            <div className="text-slate-500 leading-none">P: {safeFixed(tag.res.pressure, 2)}</div>
                        </div>
                        ))}

                    </div>
                    </div>

                    {/* Status Indicator */}
                    <div className="absolute bottom-4 right-4 bg-white/90 backdrop-blur px-3 py-1.5 rounded-full text-xs font-bold text-slate-600 shadow-sm border border-slate-200 pointer-events-none">
                    MODE: {mode === 'scale' ? 'ลากเส้นเพื่อกำหนดสเกล' : mode === 'draw' ? `วาดท่อ (${selectedPipeSize}") - Snapping Active` : mode === 'sprinkler' ? 'วางหัวสปริงเกอร์ (Auto-Assign)' : mode === 'delete' ? 'คลิกที่วัตถุเพื่อลบ' : 'ดูและเลื่อนแบบ'}
                    </div>

                    {/* Scale Dialog */}
                    {showScaleDialog && (
                    <div className="absolute inset-0 bg-black/40 flex items-center justify-center z-50">
                        <div className="bg-white p-6 rounded-2xl shadow-2xl w-80 animate-in fade-in zoom-in duration-200">
                            <h2 className="text-lg font-bold text-slate-800 mb-4 text-center">กำหนดระยะจริง</h2>
                            <div className="flex items-center gap-2 mb-6">
                            <input 
                                type="number" 
                                value={realWorldDist} 
                                onChange={(e) => setRealWorldDist(e.target.value)}
                                className="w-full bg-slate-100 border-none rounded-xl p-4 text-2xl font-black text-center outline-none focus:ring-2 focus:ring-red-500 transition-all placeholder:text-slate-300"
                                placeholder="0.00"
                                autoFocus
                            />
                            <span className="font-bold text-slate-400">m.</span>
                            </div>
                            <div className="flex gap-2">
                            <button onClick={() => { setShowScaleDialog(false); setScalePoints([]); }} className="flex-1 py-3 bg-slate-100 text-slate-500 rounded-xl font-bold text-xs uppercase tracking-widest hover:bg-slate-200 transition-colors">ยกเลิก</button>
                            <button onClick={applyScale} className="flex-1 py-3 bg-red-600 text-white rounded-xl font-bold text-xs uppercase tracking-widest hover:bg-red-700 transition-colors shadow-lg shadow-red-200">ยืนยันสเกล</button>
                            </div>
                        </div>
                    </div>
                    )}

                    {/* Results Panel */}
                    <div className="absolute bottom-4 left-4 w-64 bg-white/95 backdrop-blur border border-slate-200 rounded-xl shadow-xl overflow-hidden max-h-64 flex flex-col">
                        <div className="p-3 bg-slate-50 border-b border-slate-100 font-bold text-xs text-slate-500 uppercase tracking-wider">
                        ตารางการคำนวณ
                        </div>
                        <div className="overflow-y-auto p-2 space-y-2">
                        {pixelsPerMeter ? (
                            (results || []).length > 0 ? results.map((res, i) => (
                                <div key={i} className="bg-white border border-slate-100 p-2 rounded hover:border-blue-300 transition-colors text-xs">
                                <div className="flex justify-between font-bold text-slate-700">
                                    <span>{res.id}</span>
                                    <span>{res.size === "-" ? "จุดเริ่ม" : `${res.size}"`}</span>
                                </div>
                                <div className="flex justify-between text-slate-500 mt-1">
                                    <span>ความยาว:</span> <span>{safeFixed(res.lengthM, 2)} m.</span>
                                </div>
                                <div className="flex justify-between text-slate-500">
                                    <span>อัตราไหล:</span> <span className="font-medium text-blue-600">{safeFixed(res.flow, 1)} GPM</span>
                                </div>
                                
                                {res.addedFlow > 0 && <div className="flex justify-between text-emerald-600 font-bold bg-emerald-50 px-1 rounded my-0.5">
                                    <span>+Head Flow:</span> <span>Included</span>
                                </div>}

                                <div className="flex justify-between text-slate-400 text-[10px] mt-1 pt-1 border-t border-slate-50">
                                    <span>Friction Loss:</span> <span>+{safeFixed(res.loss, 3)} PSI</span>
                                </div>
                                <div className="text-right text-[9px] text-slate-300">(Vel: {safeFixed(res.velocity, 1)} fps)</div>
                                <div className="flex justify-between font-bold text-slate-800 mt-1 bg-slate-50 p-1 rounded">
                                    <span>แรงดันรวม:</span> <span>{safeFixed(res.pressure, 2)} PSI</span>
                                </div>
                                </div>
                            )) : (
                                <div className="text-center py-8 text-slate-400 text-xs">
                                กดปุ่ม Calculate เพื่อเริ่มคำนวณ
                                </div>
                            )
                        ) : (
                            <div className="text-center py-8 text-red-400 text-xs font-medium">
                                กรุณากำหนดสเกลก่อน <br/> กดปุ่มไม้บรรทัดแล้วลากเส้นทับระยะที่มีในแบบ
                            </div>
                        )}
                        </div>
                    </div>

                </div>
                </div>
            );
        };

        // Render the app
        const root = createRoot(document.getElementById('root'));
        root.render(<App />);
    </script>
</body>
</html>
